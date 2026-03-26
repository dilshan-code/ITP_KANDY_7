const mongoose = require('mongoose');

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
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
        this.notificationRepository = notificationRepository;
    }

    async execute(saleData, ownerId) {
        if (!saleData || !ownerId) throw new Error('Sale data and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            // 1. Fetch Customer if present
            let customerDoc = null;
            if (saleData.customerId) {
                customerDoc = await this.customerRepository.getById(saleData.customerId, ownerId, session);
            }

            // 2. Fetch all Products for stock update and pricing
            const productDocs = [];
            if (saleData.items && saleData.items.length > 0) {
                for (let i = 0; i < saleData.items.length; i++) {
                    const item = saleData.items[i];
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, session);
                        if (product) {
                            productDocs.push({ item, product });
                            // Store cost price on the item for historical accuracy
                            saleData.items[i].purchasePrice = product.purchasePrice || 0;
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
            const sale = await this.saleRepository.create(finalSaleData, session);

            // 2. Update stock for each product
            for (const { item, product } of productDocs) {
                const quantity = parseInt(item.quantity) || 0;
                const newStock = Math.max(0, (product.stockQuantity || 0) - quantity);
                await this.productRepository.update(product.id, { 
                    stockQuantity: newStock,
                    isLowStock: newStock <= (product.minimumStockLevel || 0)
                }, ownerId, session);

                // Trigger Notifications
                if (product.notifyOutOfStock) {
                    if (newStock === 0) {
                        await this.notificationRepository.create({
                            ownerId,
                            type: 'warning',
                            title: 'Product Out of Stock',
                            message: `The product "${product.name}" is now out of stock.`,
                        }, session);
                    } else if (newStock <= (product.minimumStockLevel || 0)) {
                        await this.notificationRepository.create({
                            ownerId,
                            type: 'info',
                            title: 'Low Stock Alert',
                            message: `The product "${product.name}" is running low (${newStock} remaining).`,
                        }, session);
                    }
                }
            }

            // 3. Finalize Customer balance and Credit History
            if (customerDoc) {
                if (saleData.paymentMethod === 'credit') {
                    const totalAmount = parseFloat(saleData.totalAmount) || 0;
                    const newOutstanding = (customerDoc.totalOutstanding || 0) + totalAmount;
                    await this.customerRepository.update(customerDoc.id, { totalOutstanding: newOutstanding, status: 'active' }, ownerId, session);

                    await this.creditTransactionRepository.create({
                        ownerId,
                        customerId: customerDoc.id,
                        type: 'credit',
                        title: `Purchase Loan (Sale ${sale.id || 'N/A'})`,
                        amount: saleData.totalAmount || 0,
                        date: new Date().toISOString()
                    }, session);

                    if (newOutstanding >= (customerDoc.creditLimit || 0)) {
                        await this.notificationRepository.create({
                            ownerId,
                            type: 'alert',
                            title: 'Credit Limit Exceeded',
                            message: `${customerDoc.name} has exceeded their credit limit. Current debt: Rs ${newOutstanding}.`,
                        }, session);
                    }
                } else if (saleData.paymentMethod === 'settlement') {
                    const settleAmount = parseFloat(finalSaleData.totalAmount) || 0;
                    const newOutstanding = Math.max(0, (customerDoc.totalOutstanding || 0) - settleAmount);
                    const newStatus = newOutstanding <= 0 ? 'paid' : 'active';
                    
                    await this.customerRepository.update(customerDoc.id, { 
                        totalOutstanding: newOutstanding,
                        status: newStatus
                    }, ownerId, session);

                    await this.creditTransactionRepository.create({
                        ownerId,
                        customerId: customerDoc.id,
                        type: 'payment',
                        title: settleAmount === customerDoc.totalOutstanding ? 'Full Balance Settlement' : 'Partial Credit Payment',
                        amount: settleAmount,
                        date: new Date().toISOString()
                    }, session);
                }
            }

            await session.commitTransaction();
            return sale;
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    }
}

class GetSalesByCustomer {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(customerId, ownerId, limit = null, lastId = null) { 
        return this.saleRepository.getByCustomer(customerId, ownerId, limit, lastId); 
    }
}

class DeleteSale {
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
    }

    async execute(id, ownerId) {
        if (!id || !ownerId) throw new Error('Sale ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            const sale = await this.saleRepository.getById(id, ownerId, session);
            if (!sale) return false;

            // Revert stock
            if (sale.items && sale.items.length > 0) {
                for (const item of sale.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, session);
                        if (product) {
                            const quantity = parseInt(item.quantity) || 0;
                            const newStock = (product.stockQuantity || 0) + quantity;
                            await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId, session);
                        }
                    }
                }
            }

            // Revert customer credit
            if (sale.paymentMethod === 'credit' && sale.customerId) {
                const customer = await this.customerRepository.getById(sale.customerId, ownerId, session);
                if (customer) {
                    const totalAmount = parseFloat(sale.totalAmount) || 0;
                    const newOutstanding = Math.max(0, (customer.totalOutstanding || 0) - totalAmount);
                    await this.customerRepository.update(customer.id, { 
                        totalOutstanding: newOutstanding,
                        status: newOutstanding <= 0 ? 'paid' : 'active'
                    }, ownerId, session);
                    
                    // Cleanup the credit transaction record associated with this sale
                    await this.creditTransactionRepository.deleteByTitle(
                        ownerId, 
                        sale.customerId, 
                        `(Sale ${id})`, 
                        session
                    );
                }
            }

            await this.saleRepository.delete(id, ownerId, session);
            await session.commitTransaction();
            return true;
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    }
}

class UpdateSale {
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
        this.notificationRepository = notificationRepository;
    }

    async execute(id, saleData, ownerId) {
        if (!id || !ownerId) throw new Error('Sale ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            const oldSale = await this.saleRepository.getById(id, ownerId, session);
            if (!oldSale) throw new Error('Sale not found');

            // 1. REVERT OLD STOCK
            if (oldSale.items && oldSale.items.length > 0) {
                for (const item of oldSale.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, session);
                        if (product) {
                            const quantity = parseInt(item.quantity) || 0;
                            const revertedStock = (product.stockQuantity || 0) + quantity;
                            await this.productRepository.update(product.id, { stockQuantity: revertedStock }, ownerId, session);
                        }
                    }
                }
            }

            // 2. REVERT OLD CREDIT
            if (oldSale.paymentMethod === 'credit' && oldSale.customerId) {
                const customer = await this.customerRepository.getById(oldSale.customerId, ownerId, session);
                if (customer) {
                    const totalAmount = parseFloat(oldSale.totalAmount) || 0;
                    const revertedOutstanding = Math.max(0, (customer.totalOutstanding || 0) - totalAmount);
                    await this.customerRepository.update(customer.id, { totalOutstanding: revertedOutstanding }, ownerId, session);
                    
                    // Remove old credit transaction record
                    await this.creditTransactionRepository.deleteByTitle(
                        ownerId, 
                        oldSale.customerId, 
                        `(Sale ${id})`, 
                        session
                    );
                }
            }

            // 3. APPLY NEW STOCK AND PRICE
            if (saleData.items && saleData.items.length > 0) {
                for (let i = 0; i < saleData.items.length; i++) {
                    const item = saleData.items[i];
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, session);
                        if (product) {
                            const quantity = parseInt(item.quantity) || 0;
                            const newStock = Math.max(0, (product.stockQuantity || 0) - quantity);
                            await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId, session);
                            // Store cost price on the item for historical accuracy
                            saleData.items[i].purchasePrice = product.purchasePrice || 0;
                        }
                    }
                }
            }

            // 4. APPLY NEW CREDIT
            if (saleData.paymentMethod === 'credit' && saleData.customerId) {
                const customer = await this.customerRepository.getById(saleData.customerId, ownerId, session);
                if (customer) {
                    const totalAmount = parseFloat(saleData.totalAmount || oldSale.totalAmount) || 0;
                    const newOutstanding = (customer.totalOutstanding || 0) + totalAmount;
                    await this.customerRepository.update(customer.id, { totalOutstanding: newOutstanding, status: 'active' }, ownerId, session);

                    // Create new credit transaction record
                    await this.creditTransactionRepository.create({
                        ownerId,
                        customerId: customer.id,
                        type: 'credit',
                        title: `Purchase Loan (Sale ${id})`,
                        amount: totalAmount,
                        date: new Date().toISOString()
                    }, session);
                }
            }

            const updatedSale = await this.saleRepository.update(id, saleData, ownerId, session);
            await session.commitTransaction();
            return updatedSale;
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    }
}

module.exports = { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale };
