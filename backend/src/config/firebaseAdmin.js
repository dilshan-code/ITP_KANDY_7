// Import Firebase Admin SDK (used to securely access Firebase from a backend server)
const admin = require('firebase-admin');
const path = require('path');

// --- Load service account key ---
// JSON file contains the secure credentials to authenticate with your Firebase project.
// It is stored two levels up from this current directory.
const serviceAccountPath = path.join(__dirname, '..', '..', 'serviceAccountKey.json');

let serviceAccount;
try {
    // Attempt to read the credentials file
    serviceAccount = require(serviceAccountPath);
} catch (error) {
    // If the file is missing, log an error and stop the server
    console.error('❌ Firebase service account key not found!');
    console.error(`   Expected at: ${serviceAccountPath}`);
    console.error('   Download it from: Firebase Console → Project Settings → Service accounts → Generate new private key');
    process.exit(1);
}

// Initialize the Firebase Admin application with the loaded credentials
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

// Get a reference to the Firestore database
const db = admin.firestore();

console.log('🔥 Firebase Admin SDK initialized successfully');

// Export admin and db so other files (like FirestoreProductRepository) can use them
module.exports = { admin, db };
