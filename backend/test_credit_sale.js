const { db } = require('./src/config/firebaseAdmin');
const Sale = require('./src/domain/entities/Sale');

async function testInsert() {
    // 1. get a customer
    const customers = await db.collection('customers').get();
    if (customers.empty) {
        console.log("No customers found"); return;
    }
    const customer = customers.docs[0];
    
    // 2. add a credit sale for this customer
    const saleData = {
        items: [],
        customerId: customer.id,
        customerName: customer.data().name,
        subtotal: 100,
        totalAmount: 100,
        paymentMethod: 'credit',
        status: 'completed',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
    };
    
    const docRef = await db.collection('sales').add(saleData);
    console.log("Added test credit sale for customer", customer.id, "Sale ID:", docRef.id);
    
    // 3. now read it back like the API does
    const saleDoc = await docRef.get();
    console.log("Read back:", saleDoc.data());
}
testInsert().catch(console.error);
