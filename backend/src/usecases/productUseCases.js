const { isValidPrice, isValidStock } = require('../utils/validationUtils');

// Use cases define the core business logic and actions available for products.

// This class handles fetching the entire product catalog for a store.
class GetAllProducts {
    // We inject the product repository here to keep the business logic separated from the data layer.
    constructor(productRepository) {
        // Store the repository reference for data operations.
        this.productRepository = productRepository;
    }
    // Executes the search for all products belonging to a specific owner.
    async execute(ownerId, limit = null, lastId = null) {
        // Delegate the data retrieval to the repository.
        return this.productRepository.getAll(ownerId, limit, lastId);
    }
}

class GetProductById {
    constructor(productRepository) {
        this.productRepository = productRepository;
    }
    // Retrieves a single product by its ID
    async execute(id, ownerId) {
        return this.productRepository.getById(id, ownerId);
    }
}

// Handles the logic for adding a new product to the inventory.
class CreateProduct {
    // Inject the repository to handle database persistence.
    constructor(productRepository) {
        this.productRepository = productRepository;
    }
    // Validates and saves the new product information.
    async execute(productData, ownerId) {
        // 1. Mandatory Data Check: Ensure both data and basic identification are present.
        if (!productData || !ownerId) {
            throw new Error('Product data and Owner ID are required');
        }
        
        // 2. Name Validation: Products must have a non-empty name for identification.
        if (!productData.name || productData.name.trim() === '') {
            throw new Error('Product name is required');
        }
        
        // 3. Financial Validation: Selling price must be a positive number.
        if (!isValidPrice(productData.sellingPrice)) {
            throw new Error('Valid selling price is required');
        }
        
        // 4. Inventory Validation: Minimum stock level must be a valid non-negative number.
        if (productData.minimumStockLevel !== undefined && !isValidStock(productData.minimumStockLevel)) {
            throw new Error('Valid minimum stock level is required');
        }
        return this.productRepository.create({ ...productData, ownerId });
    }
}

// Manages updates for existing products, including price or stock changes.
class UpdateProduct {
    constructor(productRepository, notificationRepository) {
        this.productRepository = productRepository;
        this.notificationRepository = notificationRepository;
    }
    // Processes the update request and triggers stock-related alerts if necessary.
    async execute(id, productData, ownerId) {
        // 1. Identification Check: IDs are necessary for routing and ownership.
        if (!id || !ownerId) {
            throw new Error('Product ID and Owner ID are required');
        }
        
        // 2. Conditional Name Validation: If name is updated, it cannot be blank.
        if (productData.name !== undefined && productData.name.trim() === '') {
            throw new Error('Product name cannot be empty');
        }
        
        // 3. Conditional Financial Validation: Ensure new price remains valid.
        if (productData.sellingPrice !== undefined && !isValidPrice(productData.sellingPrice)) {
            throw new Error('Valid selling price is required');
        }
        
        // 4. Conditional Inventory Validation: Ensure new threshold remains valid.
        if (productData.minimumStockLevel !== undefined && !isValidStock(productData.minimumStockLevel)) {
            throw new Error('Valid minimum stock level is required');
        }
        const updatedProduct = await this.productRepository.update(id, productData, ownerId);
        
        // --- NEW: Trigger Notifications for Stock Levels ---
        if (updatedProduct && updatedProduct.notifyOutOfStock) {
            if (updatedProduct.stockQuantity === 0) {
                await this.notificationRepository.create({
                    ownerId,
                    type: 'warning',
                    title: 'Product Out of Stock',
                    message: `The product "${updatedProduct.name}" is now out of stock.`,
                });
            } else if (updatedProduct.isLowStock) {
                await this.notificationRepository.create({
                    ownerId,
                    type: 'info',
                    title: 'Low Stock Alert',
                    message: `The product "${updatedProduct.name}" is running low (${updatedProduct.stockQuantity} ${updatedProduct.unit || 'units'} remaining).`,
                });
            }
        }
        
        return updatedProduct;
    }
}

// Handles the permanent removal of a product from the system.
class DeleteProduct {
    constructor(productRepository) {
        this.productRepository = productRepository;
    }
    // Deletes the product matching the provided ID and owner.
    async execute(id, ownerId) {
        return this.productRepository.delete(id, ownerId);
    }
}

module.exports = {
    GetAllProducts,
    GetProductById,
    CreateProduct,
    UpdateProduct,
    DeleteProduct,
};
