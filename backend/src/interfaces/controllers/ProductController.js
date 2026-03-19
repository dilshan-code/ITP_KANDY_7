// The Controller receives the HTTP request from the frontend (req),
// talks to the Use Cases to do the actual work,
// and sends back an HTTP response (res).
// ProductController manages the inventory. It handles adding products, tracking stock, and generating business reports.
class ProductController {
    constructor(
        { getAllProducts, getProductById, createProduct, updateProduct, deleteProduct },
        { getAllSales },
        { getAllCustomers },
        { getAllPurchases }
    ) {
        this.getAllProducts = getAllProducts;
        this.getProductById = getProductById;
        this.createProduct = createProduct;
        this.updateProduct = updateProduct;
        this.deleteProduct = deleteProduct;
        
        this.getAllSales = getAllSales;
        this.getAllCustomers = getAllCustomers;
        this.getAllPurchases = getAllPurchases;
    }

    // Handle GET /api/products
    async getAll(req, res) {
        try {
            const products = await this.getAllProducts.execute();
            // Send back a success JSON response
            res.json({ success: true, data: products });
        } catch (error) {
            // If something went wrong, send a 500 server error
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/products/:id
    async getById(req, res) {
        try {
            // req.params.id gets the ID from the URL (e.g., /api/products/123)
            const product = await this.getProductById.execute(req.params.id);
            if (!product) {
                // If not found, send a 404 response
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle POST /api/products
    async create(req, res) {
        try {
            // req.body contains the JSON data sent by the frontend
            const product = await this.createProduct.execute(req.body);
            // Send 201 Created status
            res.status(201).json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle PUT /api/products/:id
    async update(req, res) {
        try {
            const product = await this.updateProduct.execute(req.params.id, req.body);
            if (!product) {
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle DELETE /api/products/:id
    async delete(req, res) {
        try {
            const deleted = await this.deleteProduct.execute(req.params.id);
            if (!deleted) {
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, message: 'Product deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/dashboard (Calculates stats for the home screen)
    // Gathers all the important numbers for the Home Screen dashboard (like total sales today and low stock alerts).
    async getDashboard(req, res) {
        try {
            // First, retrieve every product in the database to analyze the entire inventory
            const products = await this.getAllProducts.execute();
            const sales = this.getAllSales ? await this.getAllSales.execute() : [];
            const customers = this.getAllCustomers ? await this.getAllCustomers.execute() : [];
            const purchases = this.getAllPurchases ? await this.getAllPurchases.execute() : [];
            
            // Calculate aggregate values
            const totalInventoryValue = products.reduce((sum, p) => sum + p.inventoryValue, 0);
            const totalItems = products.reduce((sum, p) => sum + p.stockQuantity, 0);
            const lowStockItems = products.filter(p => p.isLowStock);
            
            // Calculate Today's Sales
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const todaysSales = sales
                .filter(s => new Date(s.createdAt) >= today)
                .reduce((sum, s) => sum + (s.totalAmount || 0), 0);
                
            // Calculate total customer credit outstanding
            const customerCredit = customers.reduce((sum, c) => sum + (c.totalOutstanding || 0), 0);
            
            // Calculate total purchases paid to suppliers
            const toSuppliers = purchases.reduce((sum, p) => sum + (p.totalAmount || 0), 0);

            // Generate recent transactions
            let allTxns = [];
            sales.forEach(s => {
                allTxns.push({
                    id: s.id,
                    type: s.paymentMethod === 'credit' ? 'credit' : 'order',
                    title: s.paymentMethod === 'credit' ? 'Credit Sale' : `Sale #${s.id.substring(0, 5)}`,
                    subtitle: s.customerName || 'Walk-in Customer',
                    amount: s.totalAmount || 0,
                    time: s.createdAt
                });
            });
            purchases.forEach(p => {
                allTxns.push({
                    id: p.id,
                    type: 'purchase',
                    title: `Purchase #${p.id.substring(0, 5)}`,
                    subtitle: `Supplier: ${p.supplierId}`,
                    amount: -(p.totalAmount || 0),
                    time: p.purchaseDate || p.createdAt
                });
            });
            
            // Sort by time descending and take top 5
            allTxns.sort((a, b) => new Date(b.time) - new Date(a.time));
            const recentTransactions = allTxns.slice(0, 5).map(t => ({
                ...t,
                time: new Date(t.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            }));

            // Send back dashboard statistics
            res.json({
                success: true,
                data: {
                    todaysSales: todaysSales,
                    salesTrend: 0, // Could be calculated against yesterday
                    lowStockCount: lowStockItems.length,
                    lowStockItems: lowStockItems,
                    customerCredit: customerCredit,
                    toSuppliers: toSuppliers,
                    totalInventoryValue: totalInventoryValue,
                    totalItemsInStock: totalItems,
                    recentTransactions: recentTransactions,
                },
            });
        } catch (error) {
            console.error('Dashboard Error:', error);
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/reports (Aggregate data for Management Reports)
    // Generates a detailed business report, including total profit, revenue, and top-selling products.
    async getReports(req, res) {
        try {
            const products = await this.productUseCases.getAllProducts.execute();
            const sales = await this.saleUseCases.getAllSales.execute();
            const customers = await this.customerUseCases.getAllCustomers.execute();
            const purchases = await this.purchaseUseCases.getAllPurchases.execute();

            // 1. Calculate Financials
            let totalRevenue = 0;
            let totalProfit = 0;
            let totalCreditOutstanding = customers.reduce((sum, c) => sum + (c.totalOutstanding || 0), 0);
            
            // Map products for quick cost price lookup
            const productMap = {};
            products.forEach(p => { productMap[p.id] = p; });

            sales.forEach(sale => {
                totalRevenue += (sale.totalAmount || 0);
                
                // Profit calculation: Revenue - (Cost Price * Quantity)
                if (sale.items) {
                    sale.items.forEach(item => {
                        const product = productMap[item.productId];
                        if (product) {
                            const itemRevenue = (item.price || 0) * (item.quantity || 1);
                            const itemCost = (product.costPrice || 0) * (item.quantity || 1);
                            totalProfit += (itemRevenue - itemCost);
                        }
                    });
                }
            });

            // 2. Inventory Health
            const totalInventoryValue = products.reduce((sum, p) => sum + ((p.stockQuantity || 0) * (p.costPrice || 0)), 0);
            const totalStockItems = products.reduce((sum, p) => sum + (p.stockQuantity || 0), 0);
            const lowStockItemsCount = products.filter(p => p.stockQuantity <= (p.minimumStockLevel || 0)).length;

            // 3. Top Products by Revenue
            const productPerformance = {};
            sales.forEach(sale => {
                if (sale.items) {
                    sale.items.forEach(item => {
                        if (!productPerformance[item.productId]) {
                            productPerformance[item.productId] = { name: item.name, revenue: 0, quantity: 0 };
                        }
                        productPerformance[item.productId].revenue += (item.price || 0) * (item.quantity || 1);
                        productPerformance[item.productId].quantity += (item.quantity || 1);
                    });
                }
            });

            const topProducts = Object.values(productPerformance)
                .sort((a, b) => b.revenue - a.revenue)
                .slice(0, 5);

            // 4. Monthly Trend (Daily for the last 30 days)
            const dailyStats = {};
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

            sales.forEach(sale => {
                const date = new Date(sale.createdAt).toISOString().split('T')[0];
                if (new Date(sale.createdAt) >= thirtyDaysAgo) {
                    if (!dailyStats[date]) dailyStats[date] = 0;
                    dailyStats[date] += (sale.totalAmount || 0);
                }
            });

            const trendData = Object.keys(dailyStats)
                .sort()
                .map(date => ({ date, amount: dailyStats[date] }));

            res.json({
                success: true,
                data: {
                    summary: {
                        totalRevenue,
                        totalProfit,
                        totalCreditOutstanding,
                        totalPurchases: purchases.reduce((sum, p) => sum + (p.totalAmount || 0), 0)
                    },
                    inventory: {
                        totalValue: totalInventoryValue,
                        itemCount: totalStockItems,
                        lowStockCount: lowStockItemsCount
                    },
                    topProducts,
                    trend: trendData
                }
            });

        } catch (error) {
            console.error('Reports Error:', error);
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/transactions (Full list of sales and purchases formatted uniformly)
    // Retrieves a complete list of all transactions (both sales and purchases) for the history log.
    async getTransactions(req, res) {
        try {
            const sales = this.getAllSales ? await this.getAllSales.execute() : [];
            const purchases = this.getAllPurchases ? await this.getAllPurchases.execute() : [];

            let allTxns = [];
            sales.forEach(s => {
                allTxns.push({
                    id: s.id,
                    type: s.paymentMethod === 'credit' ? 'credit' : 'order',
                    title: s.paymentMethod === 'credit' ? 'Credit Sale' : `Sale #${s.id.substring(0, 5)}`,
                    subtitle: s.customerName || 'Walk-in Customer',
                    amount: s.totalAmount || 0,
                    time: s.createdAt,
                    originalDate: s.createdAt
                });
            });
            purchases.forEach(p => {
                allTxns.push({
                    id: p.id,
                    type: 'purchase',
                    title: `Purchase #${p.id.substring(0, 5)}`,
                    subtitle: `Supplier: ${p.supplierId}`,
                    amount: -(p.totalAmount || 0),
                    time: p.purchaseDate || p.createdAt,
                    originalDate: p.purchaseDate || p.createdAt
                });
            });

            // Sort by time descending
            allTxns.sort((a, b) => new Date(b.originalDate) - new Date(a.originalDate));

            // Format time for display (same as dashboard logic)
            const formattedTxns = allTxns.map(t => ({
                ...t,
                time: new Date(t.originalDate).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
                date: new Date(t.originalDate).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })
            }));

            res.json({ success: true, data: formattedTxns });
        } catch (error) {
            console.error('Transactions Error:', error);
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = ProductController;
