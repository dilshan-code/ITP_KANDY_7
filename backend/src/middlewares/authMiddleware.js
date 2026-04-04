// Middleware to extract the owner's unique ID from the request headers.
// This ID is used to filter all database operations, ensuring data isolation between different shop owners.
const authMiddleware = (req, res, next) => {
    const ownerId = req.headers['x-owner-id'];
    
    const timezoneOffset = req.headers['x-timezone-offset'];
    
    // We only enforce ownerId for API routes that manage specific shop data (products, sales, etc.)
    // Auth routes (login/register) and Admin routes (listing all owners) don't have an ownerId yet.
    if (!ownerId && !req.path.includes('/auth/') && !req.path.includes('/admin/')) {
        // In a real production app, we would verify a JWT token here and check for an 'admin' role.
        // For this implementation, we rely on the header passed by the frontend.
        return res.status(401).json({ success: false, error: 'Owner ID is required for this operation' });
    }

    req.ownerId = ownerId;
    req.timezoneOffset = timezoneOffset ? parseInt(timezoneOffset) : 0;
    next();
};

module.exports = authMiddleware;
