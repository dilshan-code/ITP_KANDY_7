// The Controller receives the HTTP request from the frontend (req),
// talks to the Use Cases to do the actual work,
// and sends back an HTTP response (res).
class ProductController {
    constructor({ getAllProducts, getProductById, createProduct, updateProduct, deleteProduct }) {
        this.getAllProducts = getAllProducts;
        this.getProductById = getProductById;
        this.createProduct = createProduct;
        this.updateProduct = updateProduct;
        this.deleteProduct = deleteProduct;
    }

    // Handle GET /api/products
    async getAll(req, res) {
        try {
            const products = await this.getAllProducts.execute();
            // Send back a success JSON response
            res.json({ success: true, data: products });
        } catch (error) {
            // If something went wrong, send a 500 server error
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/products/:id
    async getById(req, res) {
        try {
            // req.params.id gets the ID from the URL (e.g., /api/products/123)
            const product = await this.getProductById.execute(req.params.id);
            if (!product) {
                // If not found, send a 404 response
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle POST /api/products
    async create(req, res) {
        try {
            // req.body contains the JSON data sent by the frontend
            const product = await this.createProduct.execute(req.body);
            // Send 201 Created status
            res.status(201).json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle PUT /api/products/:id
    async update(req, res) {
        try {
            const product = await this.updateProduct.execute(req.params.id, req.body);
            if (!product) {
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle DELETE /api/products/:id
    async delete(req, res) {
        try {
            const deleted = await this.deleteProduct.execute(req.params.id);
            if (!deleted) {
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, message: 'Product deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/dashboard (Calculates stats for the home screen)
    async getDashboard(req, res) {
        try {
            // First, retrieve every product in the database to analyze the entire inventory
            const products = await this.getAllProducts.execute();

            // Calculate aggregate values
            // .reduce() loops through all products, adding each product's 'inventoryValue' to a running total ('sum') starting at 0
            const totalInventoryValue = products.reduce((sum, p) => sum + p.inventoryValue, 0);
            // .reduce() loops through all products, summing up the raw 'stockQuantity' count to get total items in warehouse
            const totalItems = products.reduce((sum, p) => sum + p.stockQuantity, 0);
            // .filter() creates a new list containing only products where the 'isLowStock' boolean property is true
            const lowStockItems = products.filter(p => p.isLowStock);

            // Send back dashboard statistics
            res.json({
                success: true,
                data: {
                    todaysSales: 1240.50, // Mocked for now (static data)
                    salesTrend: 12,       // Mocked for now (static data)
                    lowStockCount: lowStockItems.length, // The number of items returned by the filter above
                    lowStockItems: lowStockItems,        // The actual array of low stock products
                    customerCredit: 345.00, // Mocked for now
                    toSuppliers: 890.00,    // Mocked for now
                    totalInventoryValue: totalInventoryValue, // The sum calculated via above reduce
                    totalItemsInStock: totalItems,            // The sum calculated via above reduce
                    recentTransactions: [
                        {
                            id: 'TXN-2034',
                            type: 'order',
                            title: 'Order #2034',
                            subtitle: 'Walk-in Customer',
                            amount: 45.20,
                            time: '10:42 AM',
                        },
                        {
                            id: 'TXN-2033',
                            type: 'credit',
                            title: 'Credit Payment',
                            subtitle: 'Mr. John Doe',
                            amount: 120.00,
                            time: '09:15 AM',
                        },
                    ],
                },
            });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = ProductController;
