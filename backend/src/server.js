// Import required external modules
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/mongoConfig');

// --- Infrastructure ---
const MongoProductRepository = require('./infrastructure/MongoProductRepository');
const MongoOwnerRepository = require('./infrastructure/MongoOwnerRepository');
const MongoSupplierRepository = require('./infrastructure/MongoSupplierRepository');
const MongoPurchaseRepository = require('./infrastructure/MongoPurchaseRepository');
const MongoCustomerRepository = require('./infrastructure/MongoCustomerRepository');
const MongoCreditTransactionRepository = require('./infrastructure/MongoCreditTransactionRepository');
const MongoSaleRepository = require('./infrastructure/MongoSaleRepository');
const MongoNotificationRepository = require('./infrastructure/MongoNotificationRepository');
const MongoFeedbackRepository = require('./infrastructure/MongoFeedbackRepository');


// --- Use Cases ---
const { GetAllProducts, GetProductById, CreateProduct, UpdateProduct, DeleteProduct } = require('./usecases/productUseCases');
const { RegisterOwner, LoginOwner, GetOwnerProfile, UpdateOwnerProfile, ChangeOwnerPassword, ResetPassword, UpdateOwnerByAdmin, DeleteOwner, GetAllOwners } = require('./usecases/authUseCases');
const { GetAllSuppliers, GetSupplierById, CreateSupplier, UpdateSupplier, DeleteSupplier, GetSupplierSummary } = require('./usecases/supplierUseCases');
const { GetAllPurchases, GetPurchaseById, CreatePurchase, GetPurchasesBySupplier, UpdatePurchase, DeletePurchase } = require('./usecases/purchaseUseCases');
const { GetAllCustomers, GetCustomerById, CreateCustomer, UpdateCustomer, DeleteCustomer } = require('./usecases/customerUseCases');
const { GetAllCreditTransactions, GetCreditTransactionsByCustomer, CreateCreditTransaction, UpdateCreditTransaction, DeleteCreditTransaction } = require('./usecases/creditTransactionUseCases');
const { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale } = require('./usecases/saleUseCases');
const { GetAllNotifications, CreateNotification, MarkNotificationAsRead, MarkAllNotificationsAsRead, DeleteNotification, DeleteAllNotifications } = require('./usecases/notificationUseCases');
// --- Use Cases ---
const { GetBusinessReport } = require('./usecases/reportUseCases');
const { GetDashboardData } = require('./usecases/dashboardUseCases');
const { SubmitFeedback, GetAllFeedback, DeleteFeedback } = require('./usecases/feedbackUseCases');


// --- Interfaces ---
const ProductController = require('./interfaces/controllers/ProductController');
const AuthController = require('./interfaces/controllers/AuthController');
const SupplierController = require('./interfaces/controllers/SupplierController');
const PurchaseController = require('./interfaces/controllers/PurchaseController');
const CustomerController = require('./interfaces/controllers/CustomerController');
const CreditTransactionController = require('./interfaces/controllers/CreditTransactionController');
const SaleController = require('./interfaces/controllers/SaleController');
const NotificationController = require('./interfaces/controllers/NotificationController');
const AdminController = require('./interfaces/controllers/AdminController');
const ReportController = require('./interfaces/controllers/ReportController');
const FeedbackController = require('./interfaces/controllers/FeedbackController');


const createProductRoutes = require('./interfaces/routes/productRoutes');
const createAuthRoutes = require('./interfaces/routes/authRoutes');
const createSupplierRoutes = require('./interfaces/routes/supplierRoutes');
const createPurchaseRoutes = require('./interfaces/routes/purchaseRoutes');
const createCustomerRoutes = require('./interfaces/routes/customerRoutes');
const createCreditTransactionRoutes = require('./interfaces/routes/creditTransactionRoutes');
const createSaleRoutes = require('./interfaces/routes/saleRoutes');
const createNotificationRoutes = require('./interfaces/routes/notificationRoutes');
const createAdminRoutes = require('./interfaces/routes/adminRoutes');
const createReportRoutes = require('./interfaces/routes/reportRoutes');
const createFeedbackRoutes = require('./interfaces/routes/feedbackRoutes');


// --- Middlewares ---
const authMiddleware = require('./middlewares/authMiddleware');

// --- Dependency Injection (DI) ---
// This section is where we choose which database (repository) and logic (use cases) to use.
// By doing this here instead of inside the classes, we can easily swap components later.

// Initialize All Repositories first
const productRepository = new MongoProductRepository();
const ownerRepository = new MongoOwnerRepository();
const supplierRepository = new MongoSupplierRepository();
const purchaseRepository = new MongoPurchaseRepository();
const customerRepository = new MongoCustomerRepository();
const creditTransactionRepository = new MongoCreditTransactionRepository();
const saleRepository = new MongoSaleRepository();
const notificationRepository = new MongoNotificationRepository();
const feedbackRepository = new MongoFeedbackRepository();


// 1. Setup Product Related Logic
const productUseCases = {
    getAllProducts: new GetAllProducts(productRepository),
    getProductById: new GetProductById(productRepository),
    createProduct: new CreateProduct(productRepository),
    updateProduct: new UpdateProduct(productRepository, notificationRepository),
    deleteProduct: new DeleteProduct(productRepository),
    getDashboardData: new GetDashboardData({
        productRepository,
        saleRepository,
        purchaseRepository,
        customerRepository,
        supplierRepository
    }),
};
// Note: ProductController is instantiated at the bottom because it depends on multiple other use cases.

// Auth
const authUseCases = {
    registerOwner: new RegisterOwner(ownerRepository),
    loginOwner: new LoginOwner(ownerRepository),
    getOwnerProfile: new GetOwnerProfile(ownerRepository),
    updateOwnerProfile: new UpdateOwnerProfile(ownerRepository),
    changeOwnerPassword: new ChangeOwnerPassword(ownerRepository),
    resetPassword: new ResetPassword(ownerRepository),
    updateOwnerByAdmin: new UpdateOwnerByAdmin(ownerRepository),
    deleteOwner: new DeleteOwner(ownerRepository),
};
const authController = new AuthController(authUseCases);

// Supplier
const supplierUseCases = {
    getAllSuppliers: new GetAllSuppliers(supplierRepository),
    getSupplierById: new GetSupplierById(supplierRepository),
    createSupplier: new CreateSupplier(supplierRepository),
    updateSupplier: new UpdateSupplier(supplierRepository),
    deleteSupplier: new DeleteSupplier(supplierRepository),
    getSupplierSummary: new GetSupplierSummary(supplierRepository),
};
const supplierController = new SupplierController(supplierUseCases);

// Purchase
const purchaseUseCases = {
    getAllPurchases: new GetAllPurchases(purchaseRepository),
    getPurchaseById: new GetPurchaseById(purchaseRepository),
    createPurchase: new CreatePurchase(purchaseRepository, productRepository, supplierRepository),
    getPurchasesBySupplier: new GetPurchasesBySupplier(purchaseRepository),
    updatePurchase: new UpdatePurchase(purchaseRepository, productRepository, supplierRepository),
    deletePurchase: new DeletePurchase(purchaseRepository, productRepository, supplierRepository),
};
const purchaseController = new PurchaseController(purchaseUseCases);

// Customer
const customerUseCases = {
    getAllCustomers: new GetAllCustomers(customerRepository),
    getCustomerById: new GetCustomerById(customerRepository),
    createCustomer: new CreateCustomer(customerRepository),
    updateCustomer: new UpdateCustomer(customerRepository),
    deleteCustomer: new DeleteCustomer(customerRepository),
};
const customerController = new CustomerController(customerUseCases);

// Credit Transactions
const creditTransactionUseCases = {
    getAllCreditTransactions: new GetAllCreditTransactions(creditTransactionRepository),
    getCreditTransactionsByCustomer: new GetCreditTransactionsByCustomer(creditTransactionRepository),
    createCreditTransaction: new CreateCreditTransaction(creditTransactionRepository, customerRepository),
    updateCreditTransaction: new UpdateCreditTransaction(creditTransactionRepository, customerRepository),
    deleteCreditTransaction: new DeleteCreditTransaction(creditTransactionRepository, customerRepository),
};
const creditTransactionController = new CreditTransactionController(creditTransactionUseCases);

// Sales
const saleUseCases = {
    getAllSales: new GetAllSales(saleRepository),
    getSaleById: new GetSaleById(saleRepository),
    createSale: new CreateSale(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository),
    getSalesByCustomer: new GetSalesByCustomer(saleRepository),
    updateSale: new UpdateSale(saleRepository, productRepository, customerRepository, creditTransactionRepository, notificationRepository),
    deleteSale: new DeleteSale(saleRepository, productRepository, customerRepository, creditTransactionRepository),
};
const saleController = new SaleController(saleUseCases);

// Notifications
const notificationUseCases = {
    getAllNotifications: new GetAllNotifications(notificationRepository),
    createNotification: new CreateNotification(notificationRepository),
    markNotificationAsRead: new MarkNotificationAsRead(notificationRepository),
    markAllNotificationsAsRead: new MarkAllNotificationsAsRead(notificationRepository),
    deleteNotification: new DeleteNotification(notificationRepository),
    deleteAllNotifications: new DeleteAllNotifications(notificationRepository),
};
const notificationController = new NotificationController(notificationUseCases);

// Admin
const adminUseCases = {
    getAllOwners: new GetAllOwners(ownerRepository),
    updateOwnerProfile: authUseCases.updateOwnerByAdmin,
    deleteOwner: authUseCases.deleteOwner,
};
const adminController = new AdminController(adminUseCases);

// Report
const reportUseCases = {
    getBusinessReport: new GetBusinessReport(saleRepository, purchaseRepository, productRepository, customerRepository),
};
const reportController = new ReportController(reportUseCases);

// Feedback
const feedbackUseCases = {
    submitFeedback: new SubmitFeedback(feedbackRepository),
    getAllFeedback: new GetAllFeedback(feedbackRepository),
    deleteFeedback: new DeleteFeedback(feedbackRepository),
};
const feedbackController = new FeedbackController(feedbackUseCases);


// ProductController injection
const productController = new ProductController({
    ...productUseCases,
    ...saleUseCases,
    ...customerUseCases,
    ...purchaseUseCases,
    ...supplierUseCases
});

// --- Express App Setup ---
const app = express();
const PORT = process.env.PORT || 5001;

// Connect to MongoDB
connectDB();

app.use(cors());
app.use(express.json());

// --- Routes ---
// Auth routes have their own internal mix of public (login/register) and private endpoints
app.use('/api', createAuthRoutes(authController, authMiddleware));

// All other API routes require an ownerId header
app.use('/api', authMiddleware);

app.use('/api', createProductRoutes(productController));
app.use('/api', createSupplierRoutes(supplierController));
app.use('/api', createPurchaseRoutes(purchaseController));
app.use('/api', createCustomerRoutes(customerController));
app.use('/api', createCreditTransactionRoutes(creditTransactionController));
app.use('/api', createSaleRoutes(saleController));
app.use('/api', createNotificationRoutes(notificationController));
app.use('/api', createAdminRoutes(adminController));
app.use('/api', createReportRoutes(reportController));
app.use('/api', createFeedbackRoutes(feedbackController));


// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start server
const server = app.listen(PORT, () => {
    console.log(`✅ ClickBuy API server running on http://localhost:${PORT}`);
    console.log(`📦 Products API: http://localhost:${PORT}/api/products`);
    console.log(`🔑 Auth API: http://localhost:${PORT}/api/auth`);
    console.log(`🚚 Suppliers API: http://localhost:${PORT}/api/suppliers`);
    console.log(`📋 Purchases API: http://localhost:${PORT}/api/purchases`);
    console.log(`👥 Customers API: http://localhost:${PORT}/api/customers`);
    console.log(`💳 Credit API: http://localhost:${PORT}/api/credit-transactions`);
    console.log(`🛒 Sales API: http://localhost:${PORT}/api/sales`);
    console.log(`🔔 Notifications API: http://localhost:${PORT}/api/notifications`);
    console.log(`👤 Admin API: http://localhost:${PORT}/api/admin/owners`);
});

// Graceful shutdown handling
const gracefulShutdown = () => {
    console.log('🔄 Shutting down server...');
    server.close(() => {
        console.log('✅ Server stopped.');
        process.exit(0);
    });

    // Force exit if server doesn't close in 5 seconds
    setTimeout(() => {
        console.error('⚠️ Could not close connections in time, forcefully shutting down');
        process.exit(1);
    }, 5000);
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
