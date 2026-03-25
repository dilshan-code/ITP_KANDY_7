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
    console.error('Firebase service account key not found!');
    console.error(`   Expected at: ${serviceAccountPath}`);
    console.error('\n   --- FIX STEPS FOR TEAM ---');
    console.error('   1. Go to: Firebase Console → Project Settings → Service accounts');
    console.error('   2. Click "Generate new private key"');
    console.error('   3. Rename the downloaded file to "serviceAccountKey.json"');
    console.error('   4. Place it in the "backend/" folder root');
    console.error('   --------------------------\n');
    process.exit(1);
}

// Initialize the Firebase Admin application with the loaded credentials
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

// Get a reference to the Firestore database
const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

console.log('Firebase Admin SDK initialized successfully');

// Export admin and db so other files (like FirestoreProductRepository) can use them
module.exports = { admin, db };
