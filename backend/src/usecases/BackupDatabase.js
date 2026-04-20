const mongoose = require('mongoose'); // Interface for raw database access and collection discovery
const archiver = require('archiver'); // High-level compression library for generating ZIP archives

/**
 * Business Logic: Disaster Recovery and Data Portability Service.
 * This use case exports the entire system state into a portable ZIP archive containing JSON snapshots of every collection.
 */
class BackupDatabase {
    /**
     * Executes the backup process and pipes the resulting stream directly to the HTTP response.
     * @param {Object} res - Express response object used as the destination stream.
     */
    async execute(res) {
        try {
            // 1. Connection Check: Ensure we have a valid handle to the underlying MongoDB driver.
            const db = mongoose.connection.db;
            if (!db) {
                throw new Error('Database connection not established');
            }

            // 2. Collection Discovery: Query the database to find all logical tables (collections).
            const collections = await db.listCollections().toArray();
            
            // 3. Archiver Initialization: Configure the ZIP engine with maximum compression (Level 9).
            const archive = archiver('zip', {
                zlib: { level: 6 } // Balanced speed vs size (default is 6)
            });

            // 4. Error & Warning Boundaries: Ensure we handle any streaming failures.
            archive.on('warning', (err) => {
                if (err.code === 'ENOENT') {
                    console.warn('[BACKUP] Minor archive warning:', err);
                } else {
                    throw err;
                }
            });

            archive.on('error', (err) => {
                console.error('[BACKUP] Archiver error:', err);
                // After an error, the stream might be in a bad state. 
                // We don't throw here to avoid crashing the process, but we let 
                // the finalize step or the outer try/catch handle the cleanup.
                res.end(); 
            });

            // 5. Pipe Integration: Connect the archiver's output directly to the client.
            archive.pipe(res);

            // 6. Data Extraction Loop: Iterate through every identified collection in the store.
            for (const collectionInfo of collections) {
                const collectionName = collectionInfo.name;
                
                // 6.1 Data Retrieval: Fetch every document in the current collection.
                // NOTE: Using toArray() loads the entire collection into memory. 
                // For enterprise-scale databases, this should be refactored to use a cursor-stream.
                const documents = await db.collection(collectionName).find({}).toArray();
                
                // 6.2 Serialization: Convert binary BSON documents into human-readable JSON.
                // We use 'null, 2' for pretty-printing, making individual records auditable by hand.
                const content = JSON.stringify(documents);
                
                // 6.3 Append to Archive: Insert the JSON file into the root of the ZIP.
                archive.append(content, { name: `${collectionName}.json` });
            }

            // 7. Finalization: Sealed the ZIP archive and signal the end of the HTTP response.
            await archive.finalize();
            
            // Log success for server-side audit trails.
            console.log(`[BACKUP] Database backup completed with ${collections.length} collections.`);
        } catch (error) {
            // Error Logging: Capture and report failures in the backup pipeline.
            console.error('[BACKUP] Error during database backup:', error);
            throw error;
        }
    }
}

// Module Export: Entry point for the administrative backup utility.
module.exports = BackupDatabase;
