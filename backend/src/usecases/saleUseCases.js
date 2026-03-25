// Retrieves every sale record from the database.
class GetAllSales {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(ownerId) { return this.saleRepository.getAll(ownerId); }
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

        // Step 1: Record the sale itself in the 'sales' collection.
        const sale = await this.saleRepository.create({ ...saleData, ownerId });

        // Step 2: Loop through every item in the sale and decrease its stock in the inventory.
        if (saleData.items && saleData.items.length > 0) {
            for (const item of saleData.items) {
                if (!item.productId) continue;

                // Fetch the current product details to get its current stock level.
                const product = await this.productRepository.getById(item.productId, ownerId);
                if (product) {
                    const newStock = Math.max(0, product.stockQuantity - item.quantity);
                    // Save the updated stock back to the database.
                    await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId);

                    // --- NEW: Trigger Notification if Out of Stock ---
                    if (newStock === 0 && product.notifyOutOfStock) {
                        await this.notificationRepository.create({
                            ownerId,
                            type: 'warning',
                            title: 'Product Out of Stock',
                            message: `The product "${product.name}" is now out of stock. Please restock soon.`,
                        });
                    }
                }
            }
        }

        // Step 3: Check if this was a credit sale. If so, update the customer's debt.
        if (saleData.paymentMethod === 'credit' && saleData.customerId) {
            const customer = await this.customerRepository.getById(saleData.customerId, ownerId);
            if (customer) {
                const newOutstanding = customer.totalOutstanding + (saleData.totalAmount || 0);
                await this.customerRepository.update(customer.id, { totalOutstanding: newOutstanding }, ownerId);

                // Step 4: Create a 'credit' transaction record so the user can see history.
                await this.creditTransactionRepository.create({
                    ownerId,
                    customerId: customer.id,
                    type: 'credit',
                    title: `Purchase Loan (Sale ${sale.id || 'N/A'})`,
                    amount: saleData.totalAmount || 0,
                    date: new Date().toISOString()
                });

                // --- NEW: Trigger Notification if Limit Exceeded ---
                if (newOutstanding >= customer.creditLimit) {
                    await this.notificationRepository.create({
                        ownerId,
                        type: 'alert',
                        title: 'Credit Limit Exceeded',
                        message: `${customer.name} has exceeded their credit limit of Rs ${customer.creditLimit}. Current debt: Rs ${newOutstanding}.`,
                    });
                }
            }
        }
        return sale;
    }
}

class GetSalesByCustomer {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(customerId, ownerId) { return this.saleRepository.getByCustomer(customerId, ownerId); }
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

        // 1. Get the sale to know which items and credit to revert
        const sale = await this.saleRepository.getById(id, ownerId);
        if (!sale) return false;

        // 2. Add stock back for each item
        if (sale.items && sale.items.length > 0) {
            for (const item of sale.items) {
                if (!item.productId) continue;
                const product = await this.productRepository.getById(item.productId, ownerId);
                if (product) {
                    const newStock = product.stockQuantity + (item.quantity || 0);
                    await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId);
                }
            }
        }

        // 3. Revert customer credit if it was a credit sale
        if (sale.paymentMethod === 'credit' && sale.customerId) {
            const customer = await this.customerRepository.getById(sale.customerId, ownerId);
            if (customer) {
                const newOutstanding = Math.max(0, customer.totalOutstanding - (sale.totalAmount || 0));
                await this.customerRepository.update(customer.id, { totalOutstanding: newOutstanding }, ownerId);
                
                // Also find and delete the associated credit transaction if possible
                // (This is best effort, or we could just leave it as history but then it looks weird)
                // For now, we rely on the balance update above.
            }
        }

        // 4. Delete the sale record
        return this.saleRepository.delete(id, ownerId);
    }
}

class UpdateSale {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(id, saleData, ownerId) { return this.saleRepository.update(id, saleData, ownerId); }
}

module.exports = { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale };
