const express = require('express');

function createFeedbackRoutes(feedbackController) {
    const router = express.Router();

    // POST /api/feedback -> submit()
    router.post('/feedback', (req, res) => feedbackController.submit(req, res));

    // GET /api/admin/feedback -> getAll()
    // In server.js, we should probably protect this with an admin check if applicable, 
    // but for now it's under the general authMiddleware in server.js.
    router.get('/admin/feedback', (req, res) => feedbackController.getAll(req, res));

    // DELETE /api/admin/feedback/:id -> delete()
    router.delete('/admin/feedback/:id', (req, res) => feedbackController.delete(req, res));

    return router;
}

module.exports = createFeedbackRoutes;
