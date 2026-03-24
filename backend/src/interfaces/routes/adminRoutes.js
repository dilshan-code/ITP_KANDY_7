const express = require('express');

function createAdminRoutes(adminController) {
    const router = express.Router();
    router.get('/admin/owners', (req, res) => adminController.getOwners(req, res));
    return router;
}

module.exports = createAdminRoutes;
