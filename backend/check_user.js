const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkUser() {
    console.log('Checking for demo user...');
    const snapshot = await db.collection('owners').where('email', '==', 'demo@clickbuy.com').get();
    if (snapshot.empty) {
        console.log('❌ Demo user NOT found');
    } else {
        console.log('✅ Demo user found:');
        snapshot.forEach(doc => {
            console.log(doc.id, '=>', doc.data());
        });
    }
    process.exit(0);
}

checkUser();
