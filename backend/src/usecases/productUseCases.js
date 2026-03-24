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
        // Business Rule Reminder: We could add validation here (e.g., check if name is unique).
        // For now, we trust the incoming data and pass it to the repository.
        return this.productRepository.create(productData);
    }
}

// Updates the details (like price or stock) of an existing product.
class UpdateProduct {
    constructor(productRepository) {
        this.productRepository = productRepository;
    }
    // Updates an existing product using its ID and incoming data
    async execute(id, productData) {
        return this.productRepository.update(id, productData);
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
