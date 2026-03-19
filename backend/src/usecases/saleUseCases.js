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
    constructor(saleRepository, productRepository, customerRepository, creditTransactionRepository) {
        this.saleRepository = saleRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
        this.creditTransactionRepository = creditTransactionRepository;
    }

    async execute(saleData) {
        // 1. Create the sale record
        const sale = await this.saleRepository.create(saleData);

        // 2. Reduce inventory for each item
        console.log('📦 Sale Items:', JSON.stringify(saleData.items));
        if (saleData.items && saleData.items.length > 0) {
            console.log(`📉 Reducing stock for ${saleData.items.length} items from Sale ${sale.id || 'N/A'}`);
            for (const item of saleData.items) {
                console.log(`🔍 Processing item: ${item.name} (ID: ${item.productId}), Qty: ${item.quantity}`);
                if (!item.productId) {
                    console.warn('⚠️ Missing productId for item in sale:', item);
                    continue;
                }
                const product = await this.productRepository.getById(item.productId);
                if (product) {
                    const newStock = Math.max(0, product.stockQuantity - item.quantity);
                    console.log(`   ✅ Updating ${product.name}: ${product.stockQuantity} -> ${newStock}`);
                    await this.productRepository.update(product.id, { stockQuantity: newStock });
                } else {
                    console.warn(`⚠️ Product NOT found in DB for ID: ${item.productId}`);
                }
            }
        }

        // 3. Handle credit (loan) logic if payment method is credit
        if (saleData.paymentMethod === 'credit' && saleData.customerId) {
            const customer = await this.customerRepository.getById(saleData.customerId);
            if (customer) {
                // Update customer outstanding balance
                const newOutstanding = customer.totalOutstanding + (saleData.totalAmount || 0);
                await this.customerRepository.update(customer.id, { totalOutstanding: newOutstanding });

                // Create a credit transaction to record this loan
                await this.creditTransactionRepository.create({
                    customerId: customer.id,
                    type: 'credit',
                    title: `Purchase Loan (Sale ${sale.id || 'N/A'})`,
                    amount: saleData.totalAmount || 0,
                    date: new Date().toISOString()
                });
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
