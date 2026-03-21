const express = require('express');
const cors = require('cors');

// ─── Infrastructure ───────────────────────────────────────────────────────────
const FirestoreProductRepository = require('./infrastructure/FirestoreProductRepository');
const FirestoreSaleRepository = require('./infrastructure/FirestoreSaleRepository');

// ─── Use Cases ────────────────────────────────────────────────────────────────
const {
    GetAllProducts,
    GetProductById,
    CreateProduct,
    UpdateProduct,
    DeleteProduct,
} = require('./usecases/productUseCases');

const {
    GetAllSales,
    GetSaleById,
    CreateSale,
    GetSalesSummaryByDateRange,
    GetTotalRevenue,
} = require('./usecases/saleUseCases');

// ─── Controllers & Routes ─────────────────────────────────────────────────────
const ProductController = require('./interfaces/controllers/ProductController');
const SaleController = require('./interfaces/controllers/SaleController');
const createProductRoutes = require('./interfaces/routes/productRoutes');
const createSaleRoutes = require('./interfaces/routes/saleRoutes');

// ─── Dependency Injection — Products ─────────────────────────────────────────
const productRepository = new FirestoreProductRepository();
const productUseCases = {
    getAllProducts: new GetAllProducts(productRepository),
    getProductById: new GetProductById(productRepository),
    createProduct: new CreateProduct(productRepository),
    updateProduct: new UpdateProduct(productRepository),
    deleteProduct: new DeleteProduct(productRepository),
};
const productController = new ProductController(productUseCases);

// ─── Dependency Injection — Sales ────────────────────────────────────────────
const saleRepository = new FirestoreSaleRepository();
const saleUseCases = {
    getAllSales: new GetAllSales(saleRepository),
    getSaleById: new GetSaleById(saleRepository),
    createSale: new CreateSale(saleRepository),
    getSalesSummaryByDateRange: new GetSalesSummaryByDateRange(saleRepository),
    getTotalRevenue: new GetTotalRevenue(saleRepository),
};
const saleController = new SaleController(saleUseCases);

// ─── Express App Setup ────────────────────────────────────────────────────────
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/api', createProductRoutes(productController));
app.use('/api', createSaleRoutes(saleController));

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// ─── Start Server ─────────────────────────────────────────────────────────────
app.listen(PORT, () => {
    console.log(`✅ ClickBuy API server running on http://localhost:${PORT}`);
    console.log(`📦 Products API : http://localhost:${PORT}/api/products`);
    console.log(`🧾 Sales API    : http://localhost:${PORT}/api/sales`);
    console.log(`📊 Dashboard API: http://localhost:${PORT}/api/dashboard`);
});
