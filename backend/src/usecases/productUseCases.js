const { isValidPrice, isValidStock } = require('../utils/validationUtils');

// Use cases represent the specific "actions" a user can take with products.

// Retrieves every single product in the shop's inventory.
class GetAllProducts {
    // We inject the productRepository here so this use case doesn't depend on a specific database like Firestore.
    constructor(productRepository) {
        // Store the injected repository instance to use for data fetching
        this.productRepository = productRepository;
    }
    // This is the core 'action' method that the controller calls.
    async execute() {
        // We simply delegate the work to the repository which knows HOW to talk to the DB.
        return this.productRepository.getAll();
    }
}

class GetProductById {
    constructor(productRepository) {
        this.productRepository = productRepository;
    }
    // Retrieves a single product by its ID
    async execute(id) {
        return this.productRepository.getById(id);
    }
}

// Adds a brand new product to the shop's stock.
class CreateProduct {
    // Injects the repository to handle the actual persistence logic.
    constructor(productRepository) {
        this.productRepository = productRepository;
    }
    // This method takes the raw product data (name, price, etc.) and saves it.
    async execute(productData) {
        if (!productData.name || productData.name.trim() === '') {
            throw new Error('Product name is required');
        }
        if (!isValidPrice(productData.sellingPrice)) {
            throw new Error('Valid selling price is required');
        }
        if (productData.minimumStockLevel !== undefined && !isValidStock(productData.minimumStockLevel)) {
            throw new Error('Valid minimum stock level is required');
        }
        return this.productRepository.create(productData);
    }
}

// Updates the details (like price or stock) of an existing product.
class UpdateProduct {
    constructor(productRepository, notificationRepository) {
        this.productRepository = productRepository;
        this.notificationRepository = notificationRepository;
    }
    // Updates an existing product using its ID and incoming data
    async execute(id, productData) {
        if (productData.name !== undefined && productData.name.trim() === '') {
            throw new Error('Product name cannot be empty');
        }
        if (productData.sellingPrice !== undefined && !isValidPrice(productData.sellingPrice)) {
            throw new Error('Valid selling price is required');
        }
        if (productData.minimumStockLevel !== undefined && !isValidStock(productData.minimumStockLevel)) {
            throw new Error('Valid minimum stock level is required');
        }
        const updatedProduct = await this.productRepository.update(id, productData);
        
        // --- NEW: Trigger Notification if Out of Stock ---
        if (updatedProduct && updatedProduct.stockQuantity === 0 && updatedProduct.notifyOutOfStock) {
            console.log(`🚨 Product Out of Stock (Manual Update): ${updatedProduct.name}`);
            await this.notificationRepository.create({
                type: 'warning',
                title: 'Product Out of Stock',
                message: `The product "${updatedProduct.name}" has been updated and is now out of stock.`,
            });
        }
        
        return updatedProduct;
    }
}

// Removes a product entirely from the shop's database.
class DeleteProduct {
    constructor(productRepository) {
        this.productRepository = productRepository;
    }
    // Deletes an existing product by its ID
    async execute(id) {
        return this.productRepository.delete(id);
    }
}

module.exports = {
    GetAllProducts,
    GetProductById,
    CreateProduct,
    UpdateProduct,
    DeleteProduct,
};
