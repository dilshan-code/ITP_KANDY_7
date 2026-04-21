const authMiddleware = require('../src/middlewares/authMiddleware');
const jwt = require('jsonwebtoken');

jest.mock('jsonwebtoken');

describe('Auth Middleware', () => {
    let req, res, next;

    beforeEach(() => {
        req = { 
            headers: {}, 
            path: '/api/products',
            method: 'GET'
        };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn().mockReturnThis(),
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    test('should allow public routes without token', () => {
        req.path = '/auth/login';
        authMiddleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });

    test('should block requests with missing token', () => {
        authMiddleware(req, res, next);
        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({ 
                success: false, 
                error: expect.stringContaining('Access token is missing') 
            })
        );
        expect(next).not.toHaveBeenCalled();
    });

    test('should block requests with invalid token', () => {
        req.headers['authorization'] = 'Bearer invalid-token';
        jwt.verify.mockImplementation(() => { throw new Error('Invalid token'); });

        authMiddleware(req, res, next);
        
        expect(res.status).toHaveBeenCalledWith(403);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({ 
                success: false, 
                error: expect.stringContaining('Invalid or expired access token') 
            })
        );
    });

    test('should allow and decode valid token', () => {
        req.headers['authorization'] = 'Bearer valid-token';
        const decoded = { id: 'owner-123', name: 'John', role: 'owner' };
        jwt.verify.mockReturnValue(decoded);

        authMiddleware(req, res, next);

        expect(req.ownerId).toBe('owner-123');
        expect(req.ownerName).toBe('John');
        expect(req.userRole).toBe('owner');
        expect(next).toHaveBeenCalled();
    });

    test('should block non-admin access to admin routes', () => {
        req.path = '/api/admin/dashboard';
        req.headers['authorization'] = 'Bearer valid-token';
        const decoded = { id: 'owner-123', name: 'John', role: 'owner' };
        jwt.verify.mockReturnValue(decoded);

        authMiddleware(req, res, next);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({ 
                success: false, 
                error: expect.stringContaining('Admin privileges required') 
            })
        );
    });

    test('should allow admin access to admin routes', () => {
        req.path = '/api/admin/dashboard';
        req.headers['authorization'] = 'Bearer admin-token';
        const decoded = { id: 'admin-1', name: 'Boss', role: 'admin' };
        jwt.verify.mockReturnValue(decoded);

        authMiddleware(req, res, next);

        expect(next).toHaveBeenCalled();
    });
});
