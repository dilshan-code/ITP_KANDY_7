const { db } = require('../config/firebaseAdmin');
class GetAllPurchases {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(ownerId, limit, lastId) { return this.purchaseRepository.getAll(ownerId, limit, lastId); }
}

class GetPurchaseById {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(id, ownerId) { return this.purchaseRepository.getById(id, ownerId); }
}

// Records a new purchase from a supplier and automatically increases the stock levels of the items bought.
class CreatePurchase {
    constructor(purchaseRepository, productRepository, supplierRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(purchaseData, ownerId) {
        if (!purchaseData || !ownerId) throw new Error('Purchase data and Owner ID are required');

        return await db.runTransaction(async (transaction) => {
            // --- READ PHASE ---
            // 1. Fetch relevant products and supplier
            const productDocs = [];
            if (purchaseData.items && purchaseData.items.length > 0) {
                for (const item of purchaseData.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, transaction);
                        if (product) productDocs.push({ item, product });
                    }
                }
            }

            const supplierDoc = purchaseData.supplierId 
                ? await this.supplierRepository.getById(purchaseData.supplierId, ownerId, transaction)
                : null;

            // --- WRITE PHASE ---
            // 2. Record the purchase
            const purchase = await this.purchaseRepository.create({ ...purchaseData, ownerId }, transaction);

            // 3. Update stock levels
            for (const { item, product } of productDocs) {
                const newStock = product.stockQuantity + (item.quantity || 0);
                await this.productRepository.update(product.id, { 
                    stockQuantity: newStock,
                    isLowStock: newStock <= (product.minimumStockLevel || 0)
                }, ownerId, transaction);
            }

            // 4. Update Supplier balance
            if (supplierDoc && purchaseData.totalAmount > 0) {
                const newBalance = (supplierDoc.totalPayable || 0) + purchaseData.totalAmount;
                await this.supplierRepository.update(supplierDoc.id, { totalPayable: newBalance }, ownerId, transaction);
            }

            return purchase;
        });
    }
}

class GetPurchasesBySupplier {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(supplierId, ownerId, limit, lastId) { return this.purchaseRepository.getBySupplier(supplierId, ownerId, limit, lastId); }
}

class UpdatePurchase {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(id, purchaseData, ownerId) { return this.purchaseRepository.update(id, purchaseData, ownerId); }
}

// Deletes a purchase record and reverts the stock increase (useful if a mistake was made).
class DeletePurchase {
    constructor(purchaseRepository, productRepository, supplierRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(id, ownerId) {
        if (!id || !ownerId) throw new Error('Purchase ID and Owner ID are required');

        return await db.runTransaction(async (transaction) => {
            // --- READ PHASE ---
            // 1. Get purchase
            const purchase = await this.purchaseRepository.getById(id, ownerId, transaction);
            if (!purchase) return false;

            // 2. Fetch products and supplier
            const productDocs = [];
            if (purchase.items && purchase.items.length > 0) {
                for (const item of purchase.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, transaction);
                        if (product) productDocs.push({ item, product });
                    }
                }
            }

            const supplierDoc = purchase.supplierId 
                ? await this.supplierRepository.getById(purchase.supplierId, ownerId, transaction)
                : null;

            // --- WRITE PHASE ---
            // 3. Revert stock
            for (const { item, product } of productDocs) {
                const newStock = Math.max(0, product.stockQuantity - (item.quantity || 0));
                await this.productRepository.update(product.id, { 
                    stockQuantity: newStock,
                    isLowStock: newStock <= (product.minimumStockLevel || 0)
                }, ownerId, transaction);
            }

            // 4. Revert supplier balance
            if (supplierDoc && purchase.totalAmount > 0) {
                const newBalance = Math.max(0, (supplierDoc.totalPayable || 0) - purchase.totalAmount);
                await this.supplierRepository.update(supplierDoc.id, { totalPayable: newBalance }, ownerId, transaction);
            }

            // 5. Delete purchase
            return await this.purchaseRepository.delete(id, ownerId, transaction);
        });
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
