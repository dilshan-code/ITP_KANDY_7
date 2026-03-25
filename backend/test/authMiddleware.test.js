const authMiddleware = require('../src/middlewares/authMiddleware');

describe('Auth Middleware', () => {
    let req, res, next;

    beforeEach(() => {
        req = { headers: {}, path: '/api/products' };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn().mockReturnThis(),
        };
        next = jest.fn();
    });

    test('should block requests without x-owner-id header', () => {
        authMiddleware(req, res, next);
        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({ success: false, error: 'Owner ID is required for this operation' })
        );
        expect(next).not.toHaveBeenCalled();
    });

    test('should allow requests with x-owner-id header', () => {
        req.headers['x-owner-id'] = 'owner-123';
        authMiddleware(req, res, next);
        expect(req.ownerId).toBe('owner-123');
        expect(next).toHaveBeenCalled();
    });

    test('should allow auth routes without x-owner-id header', () => {
        req.path = '/auth/login';
        authMiddleware(req, res, next);
        expect(next).toHaveBeenCalled();
    });

    test('should set req.ownerId when header is present', () => {
        req.headers['x-owner-id'] = 'test-owner-456';
        authMiddleware(req, res, next);
        expect(req.ownerId).toBe('test-owner-456');
    });
});
