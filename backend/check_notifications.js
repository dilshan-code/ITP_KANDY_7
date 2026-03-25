const admin = require('firebase-admin');
const { db } = require('./src/config/firebaseAdmin');

async function checkNotifications() {
    const ownerId = 'DEMO_OWNER_ID'; // Replace with actual demo owner ID if different
    console.log('Checking notifications for:', ownerId);
    
    const snapshot = await db.collection('notifications')
        .where('ownerId', '==', ownerId)
        .orderBy('createdAt', 'desc')
        .limit(5)
        .get();
        
    if (snapshot.empty) {
        console.log('No notifications found.');
        return;
    }
    
    snapshot.docs.forEach(doc => {
        const data = doc.data();
        console.log(`[${data.type.toUpperCase()}] ${data.title}: ${data.message} (${data.createdAt})`);
    });
}

checkNotifications().catch(console.error);
