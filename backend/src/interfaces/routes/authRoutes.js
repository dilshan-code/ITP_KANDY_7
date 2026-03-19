const express = require('express');

function createAuthRoutes(authController) {
    const router = express.Router();
    router.post('/auth/register', (req, res) => authController.register(req, res));
    router.post('/auth/login', (req, res) => authController.login(req, res));
    router.get('/auth/profile/:id', (req, res) => authController.getProfile(req, res));
    router.put('/auth/profile/:id', (req, res) => authController.updateProfile(req, res));
    router.put('/auth/change-password/:id', (req, res) => authController.changePassword(req, res));
    return router;
}

module.exports = createAuthRoutes;
