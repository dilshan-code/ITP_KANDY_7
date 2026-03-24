const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const bcrypt = require('bcryptjs');

async function resetPassword(newPassword) {
    console.log(`Resetting password for demo@clickbuy.com to: ${newPassword}`);
    const snapshot = await db.collection('owners').where('email', '==', 'demo@clickbuy.com').get();
    
    if (snapshot.empty) {
        console.log('❌ Demo user NOT found');
    } else {
        const doc = snapshot.docs[0];
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await db.collection('owners').doc(doc.id).update({
            password: hashedPassword,
            updatedAt: new Date().toISOString()
        });
        console.log('✅ Password reset successfully!');
        
        // Verify immediately
        const updatedDoc = await db.collection('owners').doc(doc.id).get();
        const isMatch = await bcrypt.compare(newPassword, updatedDoc.data().password);
        console.log(`Verification: Password matches? ${isMatch}`);
    }
    process.exit(0);
}

resetPassword('demo1234');
