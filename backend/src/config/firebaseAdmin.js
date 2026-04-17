/**
 * Infrastructure Layer: Firebase Admin SDK Configuration.
 * Securely initializes the connection between the backend and Firebase Cloud services.
 * Primarily used for Firestore data persistence and potentially Firebase Auth migrations.
 */

const admin = require('firebase-admin'); // Core: Peer dependency for cloud interactions
const path = require('path');

// --- Logic: Secure Credential Path Resolution ---
// The serviceAccountKey.json contains private keys; it must exist at the project root.
const serviceAccountPath = path.join(__dirname, '..', '..', 'serviceAccountKey.json');

let serviceAccount;
try {
    // Validation: Attempt to load the JSON secret file into memory.
    serviceAccount = require(serviceAccountPath);
} catch (error) {
    // Fail-Fast: Provide actionable documentation in the console for the next developer.
    console.error('❌ Firebase service account key not found!');
    console.error(`   Expected at: ${serviceAccountPath}`);
    console.error('\n   --- TRANSPARENCY: FIX STEPS FOR TEAM ---');
    console.error('   1. Go to: Firebase Console → Project Settings → Service accounts');
    console.error('   2. Click "Generate new private key"');
    console.error('   3. Rename the downloaded file to "serviceAccountKey.json"');
    console.error('   4. Place it in the "backend/" folder root');
    console.error('   ----------------------------------------\n');
    process.exit(1); // Security: Critical failure exit code to prevent unauthenticated DB ops.
}

/**
 * Logic: Initializing the Singleton Firebase Application.
 * Uses the loaded certificate to establish a secure gRPC channel to Firebase.
 */
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

/**
 * Infrastructure: Firestore Database Reference.
 * Provides a globally shared database instance for the repository layer.
 */
const db = admin.firestore();

// Policy: Ignore undefined properties during writes to prevent 'Document cannot be updated with null' errors.
db.settings({ ignoreUndefinedProperties: true });

// Audit: Log success for system monitoring.
console.log('✅ Firebase Admin SDK initialized successfully');

/**
 * Exports: Shared Cloud Infrastructure.
 * 'admin': Provides access to Auth, FCM, etc.
 * 'db': Standard Firestore instance for document-based storage.
 */
module.exports = { admin, db };
