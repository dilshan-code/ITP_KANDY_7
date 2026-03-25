// Retrieves every sale record from the database.
class GetAllSales {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute() { return this.saleRepository.getAll(); }
}

class GetSaleById {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(id) { return this.saleRepository.getById(id); }
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

    async execute(saleData) {
        // Step 1: Record the sale itself in the 'sales' collection.
        const sale = await this.saleRepository.create(saleData);

        // Step 2: Loop through every item in the sale and decrease its stock in the inventory.
        console.log('📦 Sale Items:', JSON.stringify(saleData.items));
        if (saleData.items && saleData.items.length > 0) {
            console.log(`📉 Reducing stock for ${saleData.items.length} items from Sale ${sale.id || 'N/A'}`);
            for (const item of saleData.items) {
                // Ensure we have a valid productId before trying to update it.
                if (!item.productId) {
                    console.warn('⚠️ Missing productId for item in sale:', item);
                    continue;
                }
                // Fetch the current product details to get its current stock level.
                const product = await this.productRepository.getById(item.productId);
                if (product) {
                    // Calculate the new stock (ensure it never goes below zero).
                    const newStock = Math.max(0, product.stockQuantity - item.quantity);
                    console.log(`   ✅ Updating ${product.name}: ${product.stockQuantity} -> ${newStock}`);
                    // Save the updated stock back to the database.
                    await this.productRepository.update(product.id, { stockQuantity: newStock });

                    // --- NEW: Trigger Notification if Out of Stock ---
                    if (newStock === 0 && product.notifyOutOfStock) {
                        console.log(`🚨 Product Out of Stock: ${product.name}`);
                        await this.notificationRepository.create({
                            type: 'warning',
                            title: 'Product Out of Stock',
                            message: `The product "${product.name}" is now out of stock. Please restock soon.`,
                        });
                    }
                } else {
                    console.warn(`⚠️ Product NOT found in DB for ID: ${item.productId}`);
                }
            }
        }

        // Step 3: Check if this was a credit sale. If so, update the customer's debt.
        if (saleData.paymentMethod === 'credit' && saleData.customerId) {
            const customer = await this.customerRepository.getById(saleData.customerId);
            if (customer) {
                // Increase the 'totalOutstanding' amount by the total of this sale.
                const newOutstanding = customer.totalOutstanding + (saleData.totalAmount || 0);
                await this.customerRepository.update(customer.id, { totalOutstanding: newOutstanding });

                // Step 4: Create a 'credit' transaction record so the user can see history.
                await this.creditTransactionRepository.create({
                    customerId: customer.id,
                    type: 'credit',
                    title: `Purchase Loan (Sale ${sale.id || 'N/A'})`,
                    amount: saleData.totalAmount || 0,
                    date: new Date().toISOString()
                });

                // --- NEW: Trigger Notification if Limit Exceeded ---
                if (newOutstanding >= customer.creditLimit) {
                    console.log(`🚨 Credit Limit Exceeded for ${customer.name}: ${newOutstanding} >= ${customer.creditLimit}`);
                    await this.notificationRepository.create({
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
    async execute(customerId) { return this.saleRepository.getByCustomer(customerId); }
}

// Cancels a sale and reverts the stock levels for the items involved.
class DeleteSale {
    constructor(saleRepository, productRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
    }

    async execute(id) {
        // 1. Get the sale to know which items to revert
        const sale = await this.saleRepository.getById(id);
        if (!sale) return false;

        // 2. Add stock back for each item
        if (sale.items && sale.items.length > 0) {
            console.log(`📈 Reverting stock for Sale ${id}`);
            for (const item of sale.items) {
                if (!item.productId) continue;
                const product = await this.productRepository.getById(item.productId);
                if (product) {
                    const newStock = product.stockQuantity + (item.quantity || 0);
                    await this.productRepository.update(product.id, { stockQuantity: newStock });
                    console.log(`   ✅ Reverted ${product.name}: ${product.stockQuantity} -> ${newStock}`);
                }
            }
        }

        // 3. Delete the sale record
        return this.saleRepository.delete(id);
    }
}

class UpdateSale {
    constructor(saleRepository) { this.saleRepository = saleRepository; }
    async execute(id, saleData) { return this.saleRepository.update(id, saleData); }
}

module.exports = { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale };
