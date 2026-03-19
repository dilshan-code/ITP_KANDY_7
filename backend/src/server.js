// Import required external modules
const express = require('express');
const cors = require('cors');

// --- Infrastructure ---
const FirestoreProductRepository = require('./infrastructure/FirestoreProductRepository');
const FirestoreOwnerRepository = require('./infrastructure/FirestoreOwnerRepository');
const FirestoreSupplierRepository = require('./infrastructure/FirestoreSupplierRepository');
const FirestorePurchaseRepository = require('./infrastructure/FirestorePurchaseRepository');
const FirestoreCustomerRepository = require('./infrastructure/FirestoreCustomerRepository');
const FirestoreCreditTransactionRepository = require('./infrastructure/FirestoreCreditTransactionRepository');
const FirestoreSaleRepository = require('./infrastructure/FirestoreSaleRepository');
const FirestoreNotificationRepository = require('./infrastructure/FirestoreNotificationRepository');

// --- Use Cases ---
const { GetAllProducts, GetProductById, CreateProduct, UpdateProduct, DeleteProduct } = require('./usecases/productUseCases');
const { RegisterOwner, LoginOwner, GetOwnerProfile, UpdateOwnerProfile, ChangeOwnerPassword } = require('./usecases/authUseCases');
const { GetAllSuppliers, GetSupplierById, CreateSupplier, UpdateSupplier, DeleteSupplier } = require('./usecases/supplierUseCases');
const { GetAllPurchases, GetPurchaseById, CreatePurchase, GetPurchasesBySupplier, UpdatePurchase, DeletePurchase } = require('./usecases/purchaseUseCases');
const { GetAllCustomers, GetCustomerById, CreateCustomer, UpdateCustomer, DeleteCustomer } = require('./usecases/customerUseCases');
const { GetAllCreditTransactions, GetCreditTransactionsByCustomer, CreateCreditTransaction, UpdateCreditTransaction, DeleteCreditTransaction } = require('./usecases/creditTransactionUseCases');
const { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale } = require('./usecases/saleUseCases');
const { GetAllNotifications, CreateNotification, MarkNotificationAsRead, MarkAllNotificationsAsRead, DeleteNotification, DeleteAllNotifications } = require('./usecases/notificationUseCases');
const { GetAllOwners } = require('./usecases/authUseCases');
const { GetBusinessReport } = require('./usecases/reportUseCases');

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

// --- Dependency Injection ---
// Product
const productRepository = new FirestoreProductRepository();
const productUseCases = {
    getAllProducts: new GetAllProducts(productRepository),
    getProductById: new GetProductById(productRepository),
    createProduct: new CreateProduct(productRepository),
    updateProduct: new UpdateProduct(productRepository),
    deleteProduct: new DeleteProduct(productRepository),
};
// ProductController will be defined below after all dependencies are ready.

// Auth
const ownerRepository = new FirestoreOwnerRepository();
const authUseCases = {
    registerOwner: new RegisterOwner(ownerRepository),
    loginOwner: new LoginOwner(ownerRepository),
    getOwnerProfile: new GetOwnerProfile(ownerRepository),
    updateOwnerProfile: new UpdateOwnerProfile(ownerRepository),
    changeOwnerPassword: new ChangeOwnerPassword(ownerRepository),
};
const authController = new AuthController(authUseCases);

// Supplier
const supplierRepository = new FirestoreSupplierRepository();
const supplierUseCases = {
    getAllSuppliers: new GetAllSuppliers(supplierRepository),
    getSupplierById: new GetSupplierById(supplierRepository),
    createSupplier: new CreateSupplier(supplierRepository),
    updateSupplier: new UpdateSupplier(supplierRepository),
    deleteSupplier: new DeleteSupplier(supplierRepository),
};
const supplierController = new SupplierController(supplierUseCases);

// Purchase
const purchaseRepository = new FirestorePurchaseRepository();
const purchaseUseCases = {
    getAllPurchases: new GetAllPurchases(purchaseRepository),
    getPurchaseById: new GetPurchaseById(purchaseRepository),
    createPurchase: new CreatePurchase(purchaseRepository, productRepository),
    getPurchasesBySupplier: new GetPurchasesBySupplier(purchaseRepository),
    updatePurchase: new UpdatePurchase(purchaseRepository),
    deletePurchase: new DeletePurchase(purchaseRepository, productRepository),
};
const purchaseController = new PurchaseController(purchaseUseCases);

// Customer
const customerRepository = new FirestoreCustomerRepository();
const customerUseCases = {
    getAllCustomers: new GetAllCustomers(customerRepository),
    getCustomerById: new GetCustomerById(customerRepository),
    createCustomer: new CreateCustomer(customerRepository),
    updateCustomer: new UpdateCustomer(customerRepository),
    deleteCustomer: new DeleteCustomer(customerRepository),
};
const customerController = new CustomerController(customerUseCases);

// Credit Transactions
const creditTransactionRepository = new FirestoreCreditTransactionRepository();
const creditTransactionUseCases = {
    getAllCreditTransactions: new GetAllCreditTransactions(creditTransactionRepository),
    getCreditTransactionsByCustomer: new GetCreditTransactionsByCustomer(creditTransactionRepository),
    createCreditTransaction: new CreateCreditTransaction(creditTransactionRepository, customerRepository),
    updateCreditTransaction: new UpdateCreditTransaction(creditTransactionRepository),
    deleteCreditTransaction: new DeleteCreditTransaction(creditTransactionRepository),
};
const creditTransactionController = new CreditTransactionController(creditTransactionUseCases);

// Sales
const saleRepository = new FirestoreSaleRepository();
const saleUseCases = {
    getAllSales: new GetAllSales(saleRepository),
    getSaleById: new GetSaleById(saleRepository),
    createSale: new CreateSale(saleRepository, productRepository, customerRepository, creditTransactionRepository),
    getSalesByCustomer: new GetSalesByCustomer(saleRepository),
    updateSale: new UpdateSale(saleRepository),
    deleteSale: new DeleteSale(saleRepository, productRepository),
};
const saleController = new SaleController(saleUseCases);

// Notifications
const notificationRepository = new FirestoreNotificationRepository();
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
};
const adminController = new AdminController(adminUseCases);

// Report
const reportUseCases = {
    getBusinessReport: new GetBusinessReport(saleRepository, purchaseRepository, productRepository, customerRepository),
};
const reportController = new ReportController(reportUseCases);

// ProductController injection
const productController = new ProductController(
    productUseCases,
    saleUseCases,
    customerUseCases,
    purchaseUseCases
);

// --- Express App Setup ---
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// --- Routes ---
app.use('/api', createProductRoutes(productController));
app.use('/api', createAuthRoutes(authController));
app.use('/api', createSupplierRoutes(supplierController));
app.use('/api', createPurchaseRoutes(purchaseController));
app.use('/api', createCustomerRoutes(customerController));
app.use('/api', createCreditTransactionRoutes(creditTransactionController));
app.use('/api', createSaleRoutes(saleController));
app.use('/api', createNotificationRoutes(notificationController));
app.use('/api', createAdminRoutes(adminController));
app.use('/api', createReportRoutes(reportController));

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
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
