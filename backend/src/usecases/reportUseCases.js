// This use case generates a comprehensive financial and inventory report for the shop.
class GetBusinessReport {
    constructor(saleRepository, purchaseRepository, productRepository, customerRepository) {
        this.saleRepository = saleRepository;
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
    }

    async execute(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required for report generation');

        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setHours(0, 0, 0, 0);
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        const startDate = thirtyDaysAgo.toISOString();
        const endDate = new Date().toISOString();

        const startOfToday = new Date().toISOString().split('T')[0] + 'T00:00:00.000Z';
        const endOfToday = new Date().toISOString().split('T')[0] + 'T23:59:59.999Z';

        // 1. Parallel high-speed aggregations and scoped analytics retrieval
        const [
            allTimeRevenue,
            allTimePurchases,
            todaysSales,
            totalOutstanding,
            lowStockCount,
            recentSales,
            products,
            customers
        ] = await Promise.all([
            this.saleRepository.getTotalRevenue(ownerId),
            this.purchaseRepository.getTotalPurchases(ownerId),
            this.saleRepository.getTotalRevenueByDateRange(ownerId, startOfToday, endOfToday),
            this.customerRepository.getTotalOutstanding(ownerId),
            this.productRepository.getLowStockCount(ownerId),
            this.saleRepository.getAllByDateRange(ownerId, startDate, endDate),
            this.productRepository.getAll(ownerId), // Products are usually few enough to load
            this.customerRepository.getAll(ownerId) // Customers are usually few enough to load
        ]);

        // 2. Perform deep analytics only on the 30-day window
        let monthlyProfit = 0;
        let monthlyItemsSold = 0;
        const productSales = {};

        recentSales.forEach(sale => {
            monthlyItemsSold += sale.items ? sale.items.reduce((sum, item) => sum + (item.quantity || 0), 0) : 0;
            
            // Calculate Profit for this month
            let saleCost = 0;
            if (sale.items) {
                sale.items.forEach(item => {
                    // Update Top Sellers dictionary (Month Focus)
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

                    // Calculate Cost (Priority: Historical price stored on item, Fallback: Current product price)
                    const costPrice = item.purchasePrice !== undefined ? item.purchasePrice : 
                                     (products.find(p => p.id === item.productId)?.purchasePrice || 0);
                    saleCost += (costPrice * (item.quantity || 0));
                });
            }
            monthlyProfit += ((sale.totalAmount || 0) - saleCost);
        });

        // 3. Prepare Top Products List
        const topProducts = Object.values(productSales)
            .sort((a, b) => b.quantity - a.quantity)
            .slice(0, 5);

        // 4. Generate 30-Day Trend
        const dailyRevenue = {};
        recentSales.forEach(sale => {
            const dateKey = new Date(sale.createdAt).toISOString().split('T')[0];
            if (!dailyRevenue[dateKey]) dailyRevenue[dateKey] = 0;
            dailyRevenue[dateKey] += (sale.totalAmount || 0);
        });

        const trend = Array.from({ length: 30 }, (_, i) => {
            const d = new Date(thirtyDaysAgo);
            d.setDate(d.getDate() + i + 1);
            const dateStr = d.toISOString().split('T')[0];
            return {
                date: dateStr,
                revenue: dailyRevenue[dateStr] || 0
            };
        });

        const totalStockValue = products.reduce((sum, p) => sum + ((p.stockQuantity || 0) * (p.sellingPrice || 0)), 0);

        return {
            summary: {
                totalRevenue: allTimeRevenue,
                totalProfit: monthlyProfit, // Scoped to month for performance
                todaysSales: todaysSales,
                totalCreditOutstanding: totalOutstanding,
                totalPurchases: allTimePurchases,
                totalItemsSold: monthlyItemsSold,
                averageOrderValue: recentSales.length > 0 ? (recentSales.reduce((s, x) => s + x.totalAmount, 0) / recentSales.length) : 0
            },
            inventory: {
                totalValue: totalStockValue,
                itemCount: products.length,
                lowStockCount: lowStockCount,
                outOfStockProducts: products.filter(p => (p.stockQuantity || 0) <= 0).length
            },
            topProducts,
            trend,
            customerInsights: {
                totalCustomers: customers.length,
                creditCustomers: customers.filter(c => (c.totalOutstanding || 0) > 0).length
            },
            timestamp: new Date().toISOString()
        };
    }
}

module.exports = { GetBusinessReport };
