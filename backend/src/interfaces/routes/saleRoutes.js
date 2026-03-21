const express = require('express');

function createSaleRoutes(saleController) {
    const router = express.Router();

    // GET /api/sales/report?from=2026-01-01&to=2026-03-31
    // NOTE: /report must be declared BEFORE /:id so Express matches it correctly
    router.get('/sales/report', (req, res) => saleController.getReport(req, res));

    // GET /api/sales
    router.get('/sales', (req, res) => saleController.getAll(req, res));

    // GET /api/sales/:id
    router.get('/sales/:id', (req, res) => saleController.getById(req, res));

    // POST /api/sales
    router.post('/sales', (req, res) => saleController.create(req, res));

    return router;
}

module.exports = createSaleRoutes;
