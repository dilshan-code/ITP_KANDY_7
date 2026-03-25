const { db } = require('../src/config/firebaseAdmin');
const FirestoreCustomerRepository = require('../src/infrastructure/FirestoreCustomerRepository');
const FirestoreProductRepository = require('../src/infrastructure/FirestoreProductRepository');
const FirestoreSaleRepository = require('../src/infrastructure/FirestoreSaleRepository');
const FirestoreCreditTransactionRepository = require('../src/infrastructure/FirestoreCreditTransactionRepository');
const FirestoreNotificationRepository = require('../src/infrastructure/FirestoreNotificationRepository');
const { CreateSale } = require('../src/usecases/saleUseCases');

async function verifyCreditLimitNotification() {
    console.log('🚀 Starting Credit Limit Notification Verification...');

    console.log('📦 Initializing repositories...');
    const customerRepo = new FirestoreCustomerRepository();
    const productRepo = new FirestoreProductRepository();
    const saleRepo = new FirestoreSaleRepository();
    const creditRepo = new FirestoreCreditTransactionRepository();
    const notificationRepo = new FirestoreNotificationRepository();
    console.log('✅ Repositories initialized.');

    // 1. Create a test customer with a low limit
    console.log('📝 Creating test customer...');
    const customerData = {
        name: 'Test Limit Customer',
        phone: '0771234567',
        creditLimit: 1000,
        totalOutstanding: 0,
        status: 'active'
    };
    console.log('📝 Creating test customer...');
    const customer = await customerRepo.create(customerData);
    console.log(`✅ Customer created: ${customer.id} (Limit: ${customer.creditLimit})`);

    // 2. Create a test product
    console.log('📝 Creating test product...');
    const productData = {
        name: 'Expensive Item',
        sellingPrice: 1500,
        stockQuantity: 10,
        unit: 'pcs'
    };
    const product = await productRepo.create(productData);
    console.log(`✅ Product created: ${product.id}`);

    // 3. Perform a credit sale that exceeds the limit
    console.log('🛒 Performing credit sale...');
    const createSale = new CreateSale(saleRepo, productRepo, customerRepo, creditRepo, notificationRepo);
    
    const saleData = {
        customerId: customer.id,
        customerName: customer.name,
        paymentMethod: 'credit',
        totalAmount: 1500,
        items: [{
            productId: product.id,
            name: product.name,
            price: product.sellingPrice,
            quantity: 1
        }],
        date: new Date().toISOString()
    };

    await createSale.execute(saleData);
    console.log('✅ Sale completed.');

    // 4. Check if a notification was created
    console.log('🔍 Checking for notification...');
    const notifications = await notificationRepo.getAll();
    const limitNotification = notifications.find(n => 
        n.title === 'Credit Limit Exceeded' && 
        n.message.includes(customer.name)
    );

    if (limitNotification) {
        console.log('🏆 SUCCESS: Notification found in database!');
        console.log(`   Title: ${limitNotification.title}`);
        console.log(`   Message: ${limitNotification.message}`);
    } else {
        console.log('❌ FAILURE: Notification not found in database.');
    }

    // Cleanup (optional but good for repeatability)
    console.log('🧹 Cleaning up test data...');
    // await customerRepo.delete(customer.id);
    // await productRepo.delete(product.id);
    // Notification cleanup is handled by deleteAllNotification use case if needed

    console.log('🏁 Verification finished.');
    process.exit(limitNotification ? 0 : 1);
}

verifyCreditLimitNotification().catch(err => {
    console.error('💥 Error during verification:', err);
    process.exit(1);
});
