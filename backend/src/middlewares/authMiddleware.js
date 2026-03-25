// Middleware to extract the owner's unique ID from the request headers.
// This ID is used to filter all database operations, ensuring data isolation between different shop owners.
const authMiddleware = (req, res, next) => {
    const ownerId = req.headers['x-owner-id'];
    
    // We only enforce ownerId for API routes that manage data (products, sales, etc.)
    // Auth routes (login/register) don't have an ownerId yet.
    if (!ownerId && !req.path.includes('/auth/')) {
        // In a real production app, we would verify a JWT token here.
        // For this implementation, we rely on the header passed by the frontend.
        return res.status(401).json({ success: false, error: 'Owner ID is required for this operation' });
    }

    req.ownerId = ownerId;
    next();
};

module.exports = authMiddleware;
