// Controller receives HTTP request, calls Use Case, sends HTTP response
class SaleController {
    constructor({
        getAllSales,
        getSaleById,
        createSale,
        getSalesSummaryByDateRange,
        getTotalRevenue,
    }) {
        this.getAllSales = getAllSales;
        this.getSaleById = getSaleById;
        this.createSale = createSale;
        this.getSalesSummaryByDateRange = getSalesSummaryByDateRange;
        this.getTotalRevenue = getTotalRevenue;
    }

    // GET /api/sales  — returns all sales newest first
    async getAll(req, res) {
        try {
            const sales = await this.getAllSales.execute();
            res.json({ success: true, data: sales });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // GET /api/sales/:id  — returns one sale with its items
    async getById(req, res) {
        try {
            const sale = await this.getSaleById.execute(req.params.id);
            if (!sale) {
                return res.status(404).json({ success: false, error: 'Sale not found' });
            }
            res.json({ success: true, data: sale });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // POST /api/sales  — create a new sale
    // Expected body:
    // {
    //   customerName: "Nimal",
    //   isCredit: false,
    //   status: "Completed",
    //   subtotal: 1450.0,
    //   tax: 116.0,
    //   totalAmount: 1566.0,
    //   date: "2026-03-21T...",
    //   items: [
    //     { productId: "abc123", productName: "Rice", quantity: 2, unitPrice: 725.0, subTotal: 1450.0 }
    //   ]
    // }
    async create(req, res) {
        try {
            const sale = await this.createSale.execute(req.body);
            res.status(201).json({ success: true, data: sale });
        } catch (error) {
            // 400 for business rule errors, 500 for server errors
            const status = error.message.includes('must') ? 400 : 500;
            res.status(status).json({ success: false, error: error.message });
        }
    }

    // GET /api/sales/report?from=2026-01-01&to=2026-03-31
    async getReport(req, res) {
        try {
            const { from, to } = req.query;
            const sales = await this.getSalesSummaryByDateRange.execute(from, to);

            // Calculate summary totals for the report
            const totalRevenue = sales.reduce((sum, s) => sum + s.totalAmount, 0);
            const totalSales = sales.length;
            const creditSales = sales.filter(s => s.isCredit).length;
            const paidSales = totalSales - creditSales;

            res.json({
                success: true,
                data: {
                    summary: { totalRevenue, totalSales, paidSales, creditSales },
                    sales,
                },
            });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    }
}

module.exports = SaleController;
