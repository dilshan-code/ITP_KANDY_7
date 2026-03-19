// Use cases represent the specific "actions" a user can take with products.

// Retrieves every single product in the shop's inventory.
class GetAllProducts {
    constructor(productRepository) {
        // Store the injected repository instance to use for data fetching
        this.productRepository = productRepository;
    }
    // Retrieves all products from the repository
    async execute() {
        // Delegate the actual database calling logic to the repository
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
    constructor(productRepository) {
        this.productRepository = productRepository;
    }
    // Validates/creates a new product based on the incoming data
    async execute(productData) {
        // Here we could add business rules (e.g., throw error if price < 0), then save
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
