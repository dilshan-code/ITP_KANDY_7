const admin = require('firebase-admin');
const path = require('path');

async function testFirebase() {
    console.log('Testing Firebase Admin SDK initialization...');
    const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
    
    try {
        const serviceAccount = require(serviceAccountPath);
        if (!admin.apps.length) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
        }
        console.log('✅ Firebase Admin SDK initialized successfully!');
        
        // Try a simple operation (list collections or similar, without modifying data)
        const db = admin.firestore();
        const collections = await db.listCollections();
        console.log(`✅ Connected to Firestore! Found ${collections.length} collections.`);
        
        process.exit(0);
    } catch (error) {
        console.error('❌ Firebase initialization failed:', error.message);
        process.exit(1);
    }
}

testFirebase();
