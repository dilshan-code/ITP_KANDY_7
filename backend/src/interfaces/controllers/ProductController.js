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
            const products = await this.getAllProducts.execute(req.ownerId);
            res.json({ success: true, data: products });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/products/:id
    async getById(req, res) {
        try {
            const product = await this.getProductById.execute(req.params.id, req.ownerId);
            if (!product) {
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
            const product = await this.createProduct.execute(req.body, req.ownerId);
            res.status(201).json({ success: true, data: product });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle PUT /api/products/:id
    async update(req, res) {
        try {
            const product = await this.updateProduct.execute(req.params.id, req.body, req.ownerId);
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
            const deleted = await this.deleteProduct.execute(req.params.id, req.ownerId);
            if (!deleted) {
                return res.status(404).json({ success: false, error: 'Product not found' });
            }
            res.json({ success: true, message: 'Product deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Handle GET /api/dashboard (Calculates stats for the home screen)
    async getDashboard(req, res) {
        try {
            const products = await this.getAllProducts.execute(req.ownerId);
            const sales = this.getAllSales ? await this.getAllSales.execute(req.ownerId) : [];
            const customers = this.getAllCustomers ? await this.getAllCustomers.execute(req.ownerId) : [];
            const purchases = this.getAllPurchases ? await this.getAllPurchases.execute(req.ownerId) : [];
            
            // ... rest of calculations as before ...
            // Sum up the pre-calculated 'inventoryValue' property from each product entity.
            const totalInventoryValue = products.reduce((sum, p) => sum + p.inventoryValue, 0);
            // Sum up all literal items currently on shelves.
            const totalItems = products.reduce((sum, p) => sum + p.stockQuantity, 0);
            // Identify products that have fallen below their set 'minimumStockLevel'.
            const lowStockItems = products.filter(p => p.isLowStock);
            
            // Step 3: Calculate 'Today's Sales' volume.
            const today = new Date();
            today.setHours(0, 0, 0, 0); // Reset time to midnight to catch every sale since 12:00 AM today.
            const todaysSales = sales
                .filter(s => new Date(s.createdAt) >= today)
                .reduce((sum, s) => sum + (s.totalAmount || 0), 0);
                
            // Step 4: Aggregate financial liabilities (Customer credit and Supplier payments).
            const customerCredit = customers.reduce((sum, c) => sum + (c.totalOutstanding || 0), 0);
            const toSuppliers = purchases.reduce((sum, p) => sum + (p.totalAmount || 0), 0);
 
            // Step 5: Merge Sales and Purchases into a single 'Recent Activity' timeline.
            let allTxns = [];
            // Format sales as positive 'order' or 'credit' entries.
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
            // Format purchases as negative transactions (money going out).
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
            
            // Step 6: Sort by time descending and pick only the 5 most recent activities for the UI.
            allTxns.sort((a, b) => new Date(b.time) - new Date(a.time));
            const recentTransactions = allTxns.slice(0, 5).map(t => ({
                ...t,
                // Format the time string into a human-readable 12-hour format (e.g., 02:30 PM).
                time: new Date(t.time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
            }));

            // Step 7: Send the fully prepared dashboard bucket back to the mobile app.
            res.json({
                success: true,
                data: {
                    todaysSales: todaysSales,
                    salesTrend: 0, // Placeholder for future comparison logic.
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


    // Handle GET /api/transactions (Full list of sales and purchases formatted uniformly)
    // Retrieves a complete list of all transactions (both sales and purchases) for the history log.
    async getTransactions(req, res) {
        try {
            const sales = this.getAllSales ? await this.getAllSales.execute(req.ownerId) : [];
            const purchases = this.getAllPurchases ? await this.getAllPurchases.execute(req.ownerId) : [];

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
