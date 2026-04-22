const jwt = require('jsonwebtoken'); // Security: Cryptographic verification engine

// Middleware to extract and verify the owner's identity from a JWT token.
// This ensures that only authenticated users can access their specific shop data.
const authMiddleware = (req, res, next) => {
    // Strategy: Look for token in the Authorization header (Bearer scheme)
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    // Logic: Timezone is used for localized reports; fallback to 0 (UTC).
    const timezoneOffset = req.headers['x-timezone-offset'];
    req.timezoneOffset = timezoneOffset ? parseInt(timezoneOffset) : 0;

    // Boundary: Skip verification ONLY for public auth-related routes (signup/login/otp)
    // or the base health check.
    const publicAuthRoutes = [
        '/auth/register',
        '/auth/login',
        '/auth/check-availability',
        '/auth/reset-password'
    ];

    const isPublicAuthRoute = publicAuthRoutes.some(route => 
        req.path === route || req.path === `/api${route}`
    );

    if (isPublicAuthRoute || req.path.startsWith('/otp/') || req.path.startsWith('/api/otp/') || req.path === '/' || req.path === '/health' || req.path === '/api/health') {
        return next();
    }

    if (!token) {
        return res.status(401).json({ 
            success: false, 
            error: 'Authentication Required: Access token is missing.' 
        });
    }

    try {
        const JWT_SECRET = process.env.JWT_SECRET || 'clickbuy_fallback_secret_dont_use_in_prod';
        
        // Security: Cryptographically verify the token.
        const decoded = jwt.verify(token, JWT_SECRET);
        
        // Inject identity context into the request object.
        req.ownerId = decoded.id;
        req.ownerName = decoded.name;
        req.userRole = decoded.role;
        
        // RBAC: Role-Based Access Control Guard
        // Security logic: If the path is for an administrative tool, strict 'admin' role check is required.
        // Support both relative (/admin/) and full (/api/admin/) paths for robustness.
        if ((req.path.startsWith('/admin/') || req.path.startsWith('/api/admin/')) && req.userRole !== 'admin') {
            console.warn(`🛑 [AuthMiddleware] Unauthorized Admin Access Attempt by: ${req.ownerName} (${req.ownerId})`);
            return res.status(403).json({ 
                success: false, 
                error: 'Authorization Failed: Admin privileges required for this operation.' 
            });
        }
        
        next();
    } catch (error) {
        console.error('❌ [AuthMiddleware] Token Verification Failed:', error.message);
        return res.status(403).json({ 
            success: false, 
            error: 'Security Alert: Invalid or expired access token.' 
        });
    }
};

module.exports = authMiddleware;
