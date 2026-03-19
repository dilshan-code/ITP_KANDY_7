// Retrieves all records of stock purchases from suppliers.
class GetAllPurchases {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute() { return this.purchaseRepository.getAll(); }
}

class GetPurchaseById {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(id) { return this.purchaseRepository.getById(id); }
}

// Records a new purchase from a supplier and automatically increases the stock levels of the items bought.
class CreatePurchase {
    constructor(purchaseRepository, productRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
    }

    async execute(purchaseData) {
        // 1. Create the purchase record
        const purchase = await this.purchaseRepository.create(purchaseData);

        // 2. Increase inventory for each item
        if (purchaseData.items && purchaseData.items.length > 0) {
            for (const item of purchaseData.items) {
                if (!item.productId) continue;
                
                const product = await this.productRepository.getById(item.productId);
                if (product) {
                    const newStock = product.stockQuantity + (item.quantity || 0);
                    await this.productRepository.update(product.id, { stockQuantity: newStock });
                    console.log(`📈 Increased ${product.name} stock: ${product.stockQuantity} -> ${newStock}`);
                }
            }
        }

        return purchase;
    }
}

class GetPurchasesBySupplier {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(supplierId) { return this.purchaseRepository.getBySupplier(supplierId); }
}

class UpdatePurchase {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(id, purchaseData) { return this.purchaseRepository.update(id, purchaseData); }
}

// Deletes a purchase record and reverts the stock increase (useful if a mistake was made).
class DeletePurchase {
    constructor(purchaseRepository, productRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
    }

    async execute(id) {
        // 1. Get purchase to revert stock
        const purchase = await this.purchaseRepository.getById(id);
        if (!purchase) return false;

        // 2. Subtract stock for each item (revert the increase)
        if (purchase.items && purchase.items.length > 0) {
            console.log(`📉 Reverting stock for Purchase ${id}`);
            for (const item of purchase.items) {
                if (!item.productId) continue;
                const product = await this.productRepository.getById(item.productId);
                if (product) {
                    const newStock = Math.max(0, product.stockQuantity - (item.quantity || 0));
                    await this.productRepository.update(product.id, { stockQuantity: newStock });
                    console.log(`   ✅ Reverted ${product.name}: ${product.stockQuantity} -> ${newStock}`);
                }
            }
        }

        // 3. Delete purchase
        return this.purchaseRepository.delete(id);
    }
}

module.exports = { 
    GetAllPurchases, 
    GetPurchaseById, 
    CreatePurchase, 
    GetPurchasesBySupplier,
    UpdatePurchase,
    DeletePurchase
};
