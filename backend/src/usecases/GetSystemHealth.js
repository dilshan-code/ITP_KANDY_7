const mongoose = require('mongoose');

// GetSystemHealth use case fetches real-time performance and storage metrics from MongoDB.
class GetSystemHealth {
    async execute() {
        try {
            const db = mongoose.connection.db;
            if (!db) {
                return { status: 'ERROR', message: 'Database connection not established' };
            }

            // Fetch database statistics (storage, collections, etc.)
            const stats = await db.stats();
            
            // Try to fetch server status (opcounters for reads/writes)
            // Note: This might fail on some shared clusters (like MongoDB Atlas Free Tier) 
            // due to restricted admin privileges. We'll handle it gracefully.
            let opcounters = { query: 0, insert: 0, update: 0, delete: 0, getmore: 0 };
            try {
                const serverStatus = await db.admin().serverStatus();
                if (serverStatus && serverStatus.opcounters) {
                    opcounters = serverStatus.opcounters;
                }
            } catch (adminError) {
                console.warn('[HEALTH] Could not fetch serverStatus (likely permission restricted):', adminError.message);
                // Fallback: we just won't show real-time read/write counters if restricted.
            }
            
            // Format storage to MB for readability
            const storageMB = (stats.storageSize / (1024 * 1024)).toFixed(2);
            
            // Calculate total reads and writes
            const reads = (opcounters.query || 0) + (opcounters.getmore || 0);
            const writes = (opcounters.insert || 0) + (opcounters.update || 0) + (opcounters.delete || 0);

            return {
                status: 'OK',
                mongodb: {
                    storageUsed: `${storageMB} MB`,
                    reads: reads,
                    writes: writes,
                    collections: stats.collections,
                    objects: stats.objects,
                    isRestricted: opcounters.query === 0 && opcounters.insert === 0 // Hint if we couldn't get opcounters
                },
                timestamp: new Date().toISOString()
            };
        } catch (error) {
            console.error('[HEALTH] Unexpected error fetching system health:', error);
            throw new Error(`Failed to fetch system health: ${error.message}`);
        }
    }
}

module.exports = GetSystemHealth;
