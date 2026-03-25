const { db } = require('../config/firebaseAdmin');

// Retrieves every sale record from the database.
class GetAllSales {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(ownerId, limit = null, lastId = null) { 
        return this.saleRepository.getAll(ownerId, limit, lastId); 
    }
}

class GetSaleById {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(id, ownerId) { return this.saleRepository.getById(id, ownerId); }
}

// This is a complex use case that handles creating a sale, updating stock, and managing customer credit if needed.
class CreateSale {
    // This use case requires 5 different repositories to complete a single transaction.
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
        this.notificationRepository = notificationRepository;
    }

    async execute(saleData, ownerId) {
        if (!saleData || !ownerId) throw new Error('Sale data and Owner ID are required');

        return await db.runTransaction(async (transaction) => {
            // --- READ PHASE ---
            
            // 1. Fetch Customer if present
            let customerDoc = null;
            if (saleData.customerId) {
                customerDoc = await this.customerRepository.getById(saleData.customerId, ownerId, transaction);
            }

            // 2. Fetch all Products for stock update
            const productDocs = [];
            if (saleData.items && saleData.items.length > 0) {
                for (const item of saleData.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, transaction);
                        if (product) {
                            productDocs.push({ item, product });
                        }
                    }
                }
            }

            // --- CALCULATION PHASE ---
            let finalSaleData = { ...saleData, ownerId };
            if (customerDoc && saleData.paymentMethod === 'settlement') {
                const isFullSettlement = !saleData.items || saleData.items.length === 0;
                if (isFullSettlement) {
                    finalSaleData.totalAmount = customerDoc.totalOutstanding;
                    finalSaleData.subtotal = customerDoc.totalOutstanding;
                }
            }

            // --- WRITE PHASE ---

            // 1. Record the sale
            const sale = await this.saleRepository.create(finalSaleData, transaction);

            // 2. Update stock for each product
            for (const { item, product } of productDocs) {
                const newStock = Math.max(0, product.stockQuantity - (item.quantity || 0));
                await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId, transaction);

                // Trigger Notifications for Stock Levels
                if (product.notifyOutOfStock) {
                    if (newStock === 0) {
                        await this.notificationRepository.create({
                            ownerId,
                            type: 'warning',
                            title: 'Product Out of Stock',
                            message: `The product "${product.name}" is now out of stock. Please restock soon.`,
                        }, transaction);
                    } else if (newStock <= (product.minimumStockLevel || 0)) {
                        await this.notificationRepository.create({
                            ownerId,
                            type: 'info',
                            title: 'Low Stock Alert',
                            message: `The product "${product.name}" is running low on stock (${newStock} remaining).`,
                        }, transaction);
                    }
                }
            }

            // 3. Finalize Customer balance and Credit History
            if (customerDoc) {
                if (saleData.paymentMethod === 'credit') {
                    const newOutstanding = customerDoc.totalOutstanding + (saleData.totalAmount || 0);
                    await this.customerRepository.update(customerDoc.id, { totalOutstanding: newOutstanding }, ownerId, transaction);

                    await this.creditTransactionRepository.create({
                        ownerId,
                        customerId: customerDoc.id,
                        type: 'credit',
                        title: `Purchase Loan (Sale ${sale.id || 'N/A'})`,
                        amount: saleData.totalAmount || 0,
                        date: new Date().toISOString()
                    }, transaction);

                    if (newOutstanding >= customerDoc.creditLimit) {
                        await this.notificationRepository.create({
                            ownerId,
                            type: 'alert',
                            title: 'Credit Limit Exceeded',
                            message: `${customerDoc.name} has exceeded their credit limit of Rs ${customerDoc.creditLimit}. Current debt: Rs ${newOutstanding}.`,
                        }, transaction);
                    }
                } else if (saleData.paymentMethod === 'settlement') {
                    const settleAmount = finalSaleData.totalAmount;
                    const newOutstanding = Math.max(0, customerDoc.totalOutstanding - settleAmount);
                    const newStatus = newOutstanding <= 0 ? 'paid' : 'active';
                    
                    await this.customerRepository.update(customerDoc.id, { 
                        totalOutstanding: newOutstanding,
                        status: newStatus
                    }, ownerId, transaction);

                    await this.creditTransactionRepository.create({
                        ownerId,
                        customerId: customerDoc.id,
                        type: 'payment',
                        title: settleAmount === customerDoc.totalOutstanding ? 'Full Balance Settlement' : 'Partial Credit Payment',
                        amount: settleAmount,
                        date: new Date().toISOString()
                    }, transaction);
                }
            }
            return sale;
        });
    }
}

class GetSalesByCustomer {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(customerId, ownerId, limit = null, lastId = null) { 
        return this.saleRepository.getByCustomer(customerId, ownerId, limit, lastId); 
    }
}

// Cancels a sale and reverts the stock levels and customer credit for the items involved.
class DeleteSale {
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
    }

    async execute(id, ownerId) {
        if (!id || !ownerId) throw new Error('Sale ID and Owner ID are required');

        return await db.runTransaction(async (transaction) => {
            // --- READ PHASE ---
            
            // 1. Get the sale to know which items and credit to revert
            const sale = await this.saleRepository.getById(id, ownerId, transaction);
            if (!sale) return false;

            // 2. Fetch all products involved to revert stock
            const productDocs = [];
            if (sale.items && sale.items.length > 0) {
                for (const item of sale.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, transaction);
                        if (product) {
                            productDocs.push({ item, product });
                        }
                    }
                }
            }

            // 3. Fetch customer and associated credit transaction if needed
            let customerDoc = null;
            let assocTxnRef = null;
            if (sale.paymentMethod === 'credit' && sale.customerId) {
                customerDoc = await this.customerRepository.getById(sale.customerId, ownerId, transaction);
                
                // Find associated credit transaction record
                const saleIdTag = `(Sale ${id})`;
                const txnSnapshot = await transaction.get(
                    db.collection('credit-transactions')
                        .where('ownerId', '==', ownerId)
                        .where('customerId', '==', sale.customerId)
                        .where('type', '==', 'credit')
                );
                
                const assocDoc = txnSnapshot.docs.find(doc => doc.data().title.includes(saleIdTag));
                if (assocDoc) {
                    assocTxnRef = assocDoc.ref;
                }
            }

            // --- WRITE PHASE ---

            // 1. Revert stock for each product
            for (const { item, product } of productDocs) {
                const newStock = product.stockQuantity + (item.quantity || 0);
                await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId, transaction);
            }

            // 2. Revert customer credit
            if (customerDoc) {
                const newOutstanding = Math.max(0, customerDoc.totalOutstanding - (sale.totalAmount || 0));
                await this.customerRepository.update(customerDoc.id, { 
                    totalOutstanding: newOutstanding,
                    status: newOutstanding <= 0 ? 'paid' : 'active'
                }, ownerId, transaction);
                
                // Delete the associated credit transaction if found
                if (assocTxnRef) {
                    transaction.delete(assocTxnRef);
                }
            }

            // 3. Delete the sale record
            transaction.delete(db.collection('sales').doc(id));
            return true;
        });
    }
}

// Updates an existing sale and reconciles stock/credit changes.
class UpdateSale {
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
    }

    async execute(id, saleData, ownerId) {
        if (!id || !ownerId) throw new Error('Sale ID and Owner ID are required');

        return await db.runTransaction(async (transaction) => {
            // 1. Fetch the OLD sale state
            const oldSale = await this.saleRepository.getById(id, ownerId, transaction);
            if (!oldSale) throw new Error('Sale not found');

            // 2. REVERT OLD STOCK
            if (oldSale.items && oldSale.items.length > 0) {
                for (const item of oldSale.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, transaction);
                        if (product) {
                            const revertedStock = product.stockQuantity + (item.quantity || 0);
                            await this.productRepository.update(product.id, { stockQuantity: revertedStock }, ownerId, transaction);
                        }
                    }
                }
            }

            // 3. REVERT OLD CREDIT (if applicable)
            let customerDoc = null;
            if (oldSale.paymentMethod === 'credit' && oldSale.customerId) {
                customerDoc = await this.customerRepository.getById(oldSale.customerId, ownerId, transaction);
                if (customerDoc) {
                    const revertedOutstanding = Math.max(0, customerDoc.totalOutstanding - (oldSale.totalAmount || 0));
                    await this.customerRepository.update(customerDoc.id, { 
                        totalOutstanding: revertedOutstanding,
                        status: revertedOutstanding <= 0 ? 'paid' : 'active'
                    }, ownerId, transaction);
                }
            }

            // 4. APPLY NEW STOCK
            if (saleData.items && saleData.items.length > 0) {
                for (const item of saleData.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, transaction);
                        if (product) {
                            const newStock = Math.max(0, product.stockQuantity - (item.quantity || 0));
                            await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId, transaction);
                        }
                    }
                }
            }

            // 5. APPLY NEW CREDIT (if applicable)
            if (saleData.paymentMethod === 'credit' && saleData.customerId) {
                // Fetch fresh customer doc (with reverted balance)
                const freshCustomer = await this.customerRepository.getById(saleData.customerId, ownerId, transaction);
                if (freshCustomer) {
                    const newOutstanding = freshCustomer.totalOutstanding + (saleData.totalAmount || 0);
                    await this.customerRepository.update(freshCustomer.id, { 
                        totalOutstanding: newOutstanding,
                        status: 'active'
                    }, ownerId, transaction);
                }
            }

            // 6. UPDATE SALE RECORD
            return this.saleRepository.update(id, saleData, ownerId, transaction);
        });
    }
}

module.exports = { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale };
