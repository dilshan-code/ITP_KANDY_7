// Retrieves all records of stock purchases from suppliers.
class GetAllPurchases {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(ownerId) { return this.purchaseRepository.getAll(ownerId); }
}

class GetPurchaseById {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(id, ownerId) { return this.purchaseRepository.getById(id, ownerId); }
}

// Records a new purchase from a supplier and automatically increases the stock levels of the items bought.
class CreatePurchase {
    // We need both the purchase repository (for the record) and product repository (for the stock update).
    constructor(purchaseRepository, productRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
    }

    async execute(purchaseData, ownerId) {
        if (!purchaseData || !ownerId) throw new Error('Purchase data and Owner ID are required');

        // Step 1: Save the purchase transaction to the 'purchases' collection.
        const purchase = await this.purchaseRepository.create({ ...purchaseData, ownerId });

        // Step 2: Loop through the purchased items and adjust inventory upwards.
        if (purchaseData.items && purchaseData.items.length > 0) {
            for (const item of purchaseData.items) {
                if (!item.productId) continue;
                
                // Retrieve the product to find out how many we currently have.
                const product = await this.productRepository.getById(item.productId, ownerId);
                if (product) {
                    // Add the newly purchased quantity to the current stock.
                    const newStock = product.stockQuantity + (item.quantity || 0);
                    // Update the product record with the new inventory count.
                    await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId);
                }
            }
        }

        return purchase;
    }
}

class GetPurchasesBySupplier {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(supplierId, ownerId) { return this.purchaseRepository.getBySupplier(supplierId, ownerId); }
}

class UpdatePurchase {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(id, purchaseData, ownerId) { return this.purchaseRepository.update(id, purchaseData, ownerId); }
}

// Deletes a purchase record and reverts the stock increase (useful if a mistake was made).
class DeletePurchase {
    constructor(purchaseRepository, productRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
    }

    async execute(id, ownerId) {
        if (!id || !ownerId) throw new Error('Purchase ID and Owner ID are required');

        // 1. Get purchase to revert stock
        const purchase = await this.purchaseRepository.getById(id, ownerId);
        if (!purchase) return false;

        // 2. Subtract stock for each item (revert the increase)
        if (purchase.items && purchase.items.length > 0) {
            for (const item of purchase.items) {
                if (!item.productId) continue;
                const product = await this.productRepository.getById(item.productId, ownerId);
                if (product) {
                    const newStock = Math.max(0, product.stockQuantity - (item.quantity || 0));
                    await this.productRepository.update(product.id, { stockQuantity: newStock }, ownerId);
                }
            }
        }

        // 3. Delete purchase
        return this.purchaseRepository.delete(id, ownerId);
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
