// Import required external modules
const express = require('express');
const cors = require('cors');

// --- Infrastructure ---
// This handles the actual connection to the database (Firestore)
const FirestoreProductRepository = require('./infrastructure/FirestoreProductRepository');

// --- Use Cases ---
// These files contain the core business logic (rules) for the application
const {
    GetAllProducts,
    GetProductById,
    CreateProduct,
    UpdateProduct,
    DeleteProduct,
} = require('./usecases/productUseCases');

// --- Interfaces ---
// These are the controllers (handle incoming requests) and routes (URL paths)
const ProductController = require('./interfaces/controllers/ProductController');
const createProductRoutes = require('./interfaces/routes/productRoutes');

// --- Dependency Injection ---
// Here we create the database repository instance
const productRepository = new FirestoreProductRepository();

// Pass the repository into every use case so they can access the database
const useCases = {
    getAllProducts: new GetAllProducts(productRepository),
    getProductById: new GetProductById(productRepository),
    createProduct: new CreateProduct(productRepository),
    updateProduct: new UpdateProduct(productRepository),
    deleteProduct: new DeleteProduct(productRepository),
};

// Pass all use cases into the controller so it can run them when an API is called
const productController = new ProductController(useCases);

// --- Express App Setup ---
// Initialize the Express web server
const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS (Cross-Origin Resource Sharing) so frontend can communicate with backend
// This allows applications running on different ports (like Flutter UI) to send API requests here
app.use(cors());
// Parse incoming JSON requests body (this makes the JSON data accessible via req.body)
app.use(express.json());

// --- Routes ---
// Register the product routes under the '/api' prefix
app.use('/api', createProductRoutes(productController));

// A simple health check route to verify the server is running
app.get('/health', (req, res) => {
    // Respond back to the client with a JSON object containing the status and current server time
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start the server and listen on the given PORT
app.listen(PORT, () => {
    console.log(`✅ ClickBuy API server running on http://localhost:${PORT}`);
    console.log(`📦 Products API: http://localhost:${PORT}/api/products`);
    console.log(`📊 Dashboard API: http://localhost:${PORT}/api/dashboard`);
});
