const { db } = require('../src/config/firebaseAdmin');
const FirestoreProductRepository = require('../src/infrastructure/FirestoreProductRepository');
const FirestoreSaleRepository = require('../src/infrastructure/FirestoreSaleRepository');
const FirestoreCustomerRepository = require('../src/infrastructure/FirestoreCustomerRepository');
const FirestoreCreditTransactionRepository = require('../src/infrastructure/FirestoreCreditTransactionRepository');
const FirestoreNotificationRepository = require('../src/infrastructure/FirestoreNotificationRepository');
const { CreateSale } = require('../src/usecases/saleUseCases');
const { UpdateProduct } = require('../src/usecases/productUseCases');

async function verifyStockNotification() {
    console.log('Starting Stock Notification Verification...');

    const productRepo = new FirestoreProductRepository();
    const saleRepo = new FirestoreSaleRepository();
    const customerRepo = new FirestoreCustomerRepository();
    const creditRepo = new FirestoreCreditTransactionRepository();
    const notificationRepo = new FirestoreNotificationRepository();

    // 1. Create a test product with 1 unit and notifyOutOfStock: true
    console.log('📝 Creating test product with notifyOutOfStock: true...');
    const productData = {
        name: 'Test Notification Product',
        sellingPrice: 100,
        stockQuantity: 1,
        notifyOutOfStock: true,
        unit: 'pcs'
    };
    const product = await productRepo.create(productData);
    console.log(`✅ Product created: ${product.id}`);

    console.log('🏁 Verification finished.');
    process.exit(0);
}

verifyStockNotification().catch(err => {
    console.error('Error during verification:', err);
    if (err.stack) console.error(err.stack);
    process.exit(1);
});
