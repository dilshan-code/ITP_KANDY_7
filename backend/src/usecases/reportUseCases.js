/**
 * Business Logic: The "Brain" of the application's analytics engine.
 * Generates a comprehensive snapshot of the store's financial health, inventory status, and customer trends.
 */
class GetBusinessReport {
    constructor(saleRepository, purchaseRepository, productRepository, customerRepository) {
        // Injects all primary data sources for a holistic cross-module analysis
        this.saleRepository = saleRepository;
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
    }

    /**
     * Executes a complex data aggregation pipeline to produce the dashboard metrics.
     */
    async execute(ownerId) {
        // --- Security & Sanity Check ---
        if (!ownerId) throw new Error('Owner ID is required for report generation');

        // --- Temporal Window Calculation ---
        // Define the "Performance Window" (Fixed to last 30 days for consistent month-over-month context).
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setHours(0, 0, 0, 0); // Start of day 30 days ago
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const startDate = thirtyDaysAgo.toISOString();
        const endDate = new Date().toISOString(); // Current moment

        // Define "Today's Window" for the immediate daily tracking.
        const startOfToday = new Date().toISOString().split('T')[0] + 'T00:00:00.000Z';
        const endOfToday = new Date().toISOString().split('T')[0] + 'T23:59:59.999Z';

        // --- Phase 1: High-Speed Parallel Aggregation ---
        // We trigger all independent database queries simultaneously to minimize total API latency.
        const [
            allTimeRevenue,
            allTimePurchases,
            todaysSales,
            totalOutstanding,
            lowStockCount,
            recentSalesRaw,
            products,
            customers
        ] = await Promise.all([
            this.saleRepository.getTotalRevenue(ownerId), // Sum of all completed sales
            this.purchaseRepository.getTotalPurchases(ownerId), // Sum of all stock procurement costs
            this.saleRepository.getTotalRevenueByDateRange(ownerId, startOfToday, endOfToday), // Today's target
            this.customerRepository.getTotalOutstanding(ownerId), // Total money owed by credit customers
            this.productRepository.getLowStockCount(ownerId), // Count of items needing urgent reorder
            this.saleRepository.getAllByDateRange(ownerId, startDate, endDate), // Full transaction log for analysis
            this.productRepository.getAll(ownerId), // Needed for inventory valuation calculations
            this.customerRepository.getAll(ownerId) // Needed for customer insight demographics
        ]);

        // Filter for 'completed' sales to ensure our profit/loss reports aren't skewed by cancelled orders.
        const recentSales = recentSalesRaw.filter(sale => sale.status === 'completed');

        // --- Phase 2: In-Memory Analytics Processing ---
        // We perform the heavy computation in the logic layer rather than complex DB scripts for better readability and extensibility.
        let monthlyProfit = 0;
        let monthlyItemsSold = 0;
        const productSales = {}; // Dictionary to track popularity of specific items

        recentSales.forEach(sale => {
            // Tally physical units moved out of the store.
            monthlyItemsSold += sale.items ? sale.items.reduce((sum, item) => sum + (item.quantity || 0), 0) : 0;
            
            // --- Calculation: Gross Profit of the Sale ---
            // Profit = Net Revenue - Cost of Goods Sold (COGS)
            let saleCost = 0;
            if (sale.items) {
                sale.items.forEach(item => {
                    // 2.1 Track product popularity for "Top Sellers" chart
                    if (!productSales[item.productId]) {
                        productSales[item.productId] = { 
                            name: item.productName || item.name, 
                            quantity: 0, 
                            revenue: 0,
                            unit: item.unit || 'ea'
                        };
                    }
                    productSales[item.productId].quantity += (item.quantity || 0);
                    productSales[item.productId].revenue += ((item.unitPrice || item.price || 0) * (item.quantity || 0));

                    // 2.2 Reconstruct historical cost of the sale item
                    // Priority: Use the actual purchasePrice recorded on the sale item at the moment of sale.
                    // Fallback: If legacy data lacks price snapshots, use the current purchasePrice from the product master.
                    const costPrice = item.purchasePrice !== undefined ? item.purchasePrice : 
                                     (products.find(p => p.id === item.productId)?.purchasePrice || 0);
                    saleCost += (costPrice * (item.quantity || 0));
                });
            }
            // Subtract the total cost from the transaction total to get the "Net Win" (Profit).
            monthlyProfit += ((sale.totalAmount || 0) - saleCost);
        });

        // --- Phase 3: Rank Top Products ---
        // Sort items by volume sold and return the elite top-5 list.
        const topProducts = Object.values(productSales)
            .sort((a, b) => b.quantity - a.quantity)
            .slice(0, 5);

        // --- Phase 4: Construct Sales Trend (30-Day Histogram) ---
        const dailyRevenue = {};
        recentSales.forEach(sale => {
            const dateKey = new Date(sale.createdAt).toISOString().split('T')[0];
            if (!dailyRevenue[dateKey]) dailyRevenue[dateKey] = 0;
            dailyRevenue[dateKey] += (sale.totalAmount || 0);
        });

        // Loop through every single day in the window to ensure a continuous line in the chart (including zeros).
        const trend = Array.from({ length: 30 }, (_, i) => {
            const d = new Date(thirtyDaysAgo);
            d.setDate(d.getDate() + i + 1); // Step forward day by day
            const dateStr = d.toISOString().split('T')[0];
            return {
                date: dateStr,
                revenue: dailyRevenue[dateStr] || 0 // Report 0 if no sales occurred that day
            };
        });

        // --- Phase 5: Inventory Valuation ---
        // Calculate the "Wealth" sitting on the shelves (Qty on hand * Procurement Price).
        const totalStockValue = products.reduce((sum, p) => sum + ((p.stockQuantity || 0) * (p.purchasePrice || 0)), 0);

        // --- Final Result Assembly ---
        return {
            summary: {
                totalRevenue: allTimeRevenue,
                totalProfit: monthlyProfit, // Highlight monthly profitability
                todaysSales: todaysSales,
                totalCreditOutstanding: totalOutstanding,
                totalPurchases: allTimePurchases,
                totalItemsSold: monthlyItemsSold,
                // Average order value (Basket size metrics)
                averageOrderValue: recentSales.length > 0 ? (recentSales.reduce((s, x) => s + (x.totalAmount || 0), 0) / recentSales.length) : 0
            },
            inventory: {
                totalValue: totalStockValue, // Financial liquidity risk assessment
                itemCount: products.length,
                lowStockCount: lowStockCount,
                outOfStockProducts: products.filter(p => (p.stockQuantity || 0) <= 0).length
            },
            topProducts, // List for strategic purchasing decisions
            trend, // Data points for the primary growth chart
            customerInsights: {
                totalCustomers: customers.length,
                // Percentage of customers relying on merchant credit
                creditCustomers: customers.filter(c => (c.totalOutstanding || 0) > 0).length
            },
            timestamp: new Date().toISOString() // Current audit timestamp
        };
    }
}

// Module Export: Entry point for the analytics report generation logic.
module.exports = { GetBusinessReport };
