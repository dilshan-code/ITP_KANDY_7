const mongoose = require('mongoose');

class GetAllPurchases {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(ownerId, limit, lastId) { return this.purchaseRepository.getAll(ownerId, limit, lastId); }
}

class GetPurchaseById {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(id, ownerId) { return this.purchaseRepository.getById(id, ownerId); }
}

class CreatePurchase {
    constructor(purchaseRepository, productRepository, supplierRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(purchaseData, ownerId) {
        if (!purchaseData || !ownerId) throw new Error('Purchase data and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            // 1. Fetch products to update stock
            const productDocs = [];
            if (purchaseData.items && purchaseData.items.length > 0) {
                for (const item of purchaseData.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, session);
                        if (product) productDocs.push({ item, product });
                    }
                }
            }

            // 2. Fetch supplier
            const supplierDoc = purchaseData.supplierId 
                ? await this.supplierRepository.getById(purchaseData.supplierId, ownerId, session)
                : null;

            // 3. Create purchase record
            const purchase = await this.purchaseRepository.create({ ...purchaseData, ownerId }, session);

            // 4. Update stock for each product
            for (const { item, product } of productDocs) {
                const quantity = parseInt(item.quantity) || 0;
                const newStock = (product.stockQuantity || 0) + quantity;
                const newPurchasePrice = parseFloat(item.unitPrice) || product.purchasePrice || 0;
                await this.productRepository.update(product.id, { 
                    stockQuantity: newStock,
                    purchasePrice: newPurchasePrice,
                    isLowStock: newStock <= (product.minimumStockLevel || 0)
                }, ownerId, session);
            }

            // 5. Update supplier balance
            if (supplierDoc && purchaseData.totalAmount > 0) {
                const newBalance = (supplierDoc.totalPayable || 0) + (parseFloat(purchaseData.totalAmount) || 0);
                await this.supplierRepository.update(supplierDoc.id, { totalPayable: newBalance }, ownerId, session);
            }

            await session.commitTransaction();
            return purchase;
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    }
}

class GetPurchasesBySupplier {
    constructor(purchaseRepository) { this.purchaseRepository = purchaseRepository; }
    async execute(supplierId, ownerId, limit, lastId) { return this.purchaseRepository.getBySupplier(supplierId, ownerId, limit, lastId); }
}

class UpdatePurchase {
    constructor(purchaseRepository, productRepository, supplierRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(id, purchaseData, ownerId) {
        if (!id || !ownerId) throw new Error('Purchase ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            const oldPurchase = await this.purchaseRepository.getById(id, ownerId, session);
            if (!oldPurchase) throw new Error('Purchase not found');

            // 1. REVERT OLD STOCK
            if (oldPurchase.items && oldPurchase.items.length > 0) {
                for (const item of oldPurchase.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, session);
                        if (product) {
                            const quantity = parseInt(item.quantity) || 0;
                            const revertedStock = Math.max(0, (product.stockQuantity || 0) - quantity);
                            await this.productRepository.update(product.id, { 
                                stockQuantity: revertedStock,
                                isLowStock: revertedStock <= (product.minimumStockLevel || 0)
                            }, ownerId, session);
                        }
                    }
                }
            }

            // 2. REVERT OLD SUPPLIER BALANCE
            if (oldPurchase.supplierId && oldPurchase.totalAmount > 0) {
                const supplier = await this.supplierRepository.getById(oldPurchase.supplierId, ownerId, session);
                if (supplier) {
                    const revertedBalance = Math.max(0, (supplier.totalPayable || 0) - (oldPurchase.totalAmount || 0));
                    await this.supplierRepository.update(supplier.id, { totalPayable: revertedBalance }, ownerId, session);
                }
            }

            // 3. APPLY NEW STOCK
            if (purchaseData.items && purchaseData.items.length > 0) {
                for (const item of purchaseData.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, session);
                        if (product) {
                            const quantity = parseInt(item.quantity) || 0;
                            const newStock = (product.stockQuantity || 0) + quantity;
                            const newPurchasePrice = parseFloat(item.unitPrice || item.price) || product.purchasePrice || 0;
                            await this.productRepository.update(product.id, { 
                                stockQuantity: newStock,
                                purchasePrice: newPurchasePrice,
                                isLowStock: newStock <= (product.minimumStockLevel || 0)
                            }, ownerId, session);
                        }
                    }
                }
            }

            // 4. APPLY NEW SUPPLIER BALANCE
            if (purchaseData.supplierId && purchaseData.totalAmount > 0) {
                const supplier = await this.supplierRepository.getById(purchaseData.supplierId, ownerId, session);
                if (supplier) {
                    const newBalance = (supplier.totalPayable || 0) + (parseFloat(purchaseData.totalAmount) || 0);
                    await this.supplierRepository.update(supplier.id, { totalPayable: newBalance }, ownerId, session);
                }
            }

            const updatedPurchase = await this.purchaseRepository.update(id, purchaseData, ownerId, session);
            await session.commitTransaction();
            return updatedPurchase;
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    }
}

class DeletePurchase {
    constructor(purchaseRepository, productRepository, supplierRepository) {
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.supplierRepository = supplierRepository;
    }

    async execute(id, ownerId) {
        if (!id || !ownerId) throw new Error('Purchase ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            const purchase = await this.purchaseRepository.getById(id, ownerId, session);
            if (!purchase) return false;

            const productDocs = [];
            if (purchase.items && purchase.items.length > 0) {
                for (const item of purchase.items) {
                    if (item.productId) {
                        const product = await this.productRepository.getById(item.productId, ownerId, session);
                        if (product) productDocs.push({ item, product });
                    }
                }
            }

            const supplierDoc = purchase.supplierId 
                ? await this.supplierRepository.getById(purchase.supplierId, ownerId, session)
                : null;

            for (const { item, product } of productDocs) {
                const quantity = parseInt(item.quantity) || 0;
                const newStock = Math.max(0, (product.stockQuantity || 0) - quantity);
                await this.productRepository.update(product.id, { 
                    stockQuantity: newStock,
                    isLowStock: newStock <= (product.minimumStockLevel || 0)
                }, ownerId, session);
            }

            if (supplierDoc && purchase.totalAmount > 0) {
                const newBalance = Math.max(0, (supplierDoc.totalPayable || 0) - purchase.totalAmount);
                await this.supplierRepository.update(supplierDoc.id, { totalPayable: newBalance }, ownerId, session);
            }

            await this.purchaseRepository.delete(id, ownerId, session);
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

module.exports = { GetAllPurchases, GetPurchaseById, CreatePurchase, GetPurchasesBySupplier, UpdatePurchase, DeletePurchase };
