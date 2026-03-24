const { db } = require('./src/config/firebaseAdmin');

async function run() {
    const snapshot = await db.collection('sales').get();
    snapshot.forEach(doc => {
        console.log("SALE:", doc.id, doc.data().paymentMethod, doc.data().customerId, doc.data().customerName);
    });
}
run().catch(console.error);
