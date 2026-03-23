// This use case generates a comprehensive financial and inventory report for the shop.
class GetBusinessReport {
    constructor(saleRepository, purchaseRepository, productRepository, customerRepository) {
        this.saleRepository = saleRepository;
        this.purchaseRepository = purchaseRepository;
        this.productRepository = productRepository;
        this.customerRepository = customerRepository;
    }

    async execute() {
        // Fetch all necessary data
        const [sales, purchases, products, customers] = await Promise.all([
            this.saleRepository.getAll(),
            this.purchaseRepository.getAll(),
            this.productRepository.getAll(),
            this.customerRepository.getAll()
        ]);

        let totalRevenue = 0;
        let totalItemsSold = 0;
        let totalCost = 0;

        sales.forEach(sale => {
            totalRevenue += sale.totalAmount || 0;
            totalItemsSold += sale.items ? sale.items.reduce((sum, item) => sum + (item.quantity || 0), 0) : 0;
            
            // Calculate approximate cost if possible
            if (sale.items) {
                sale.items.forEach(item => {
                    const product = products.find(p => p.id === item.productId);
                    if (product && product.purchasePrice) {
                        totalCost += (product.purchasePrice * (item.quantity || 0));
                    }
                });
            }
        });

        const totalProfit = totalRevenue - totalCost;

        // 2. Inventory Health: Identifies products that are running low or out of stock.
        const lowStockProducts = products.filter(p => p.stockQuantity <= (p.minimumStockLevel || 5)).length;
        const outOfStockProducts = products.filter(p => p.stockQuantity <= 0).length;
        const totalStockValue = products.reduce((sum, p) => sum + ((p.stockQuantity || 0) * (p.sellingPrice || 0)), 0);

        // 3. Top Selling Products: Ranks items based on how many have been sold.
        const productSales = {};
        sales.forEach(sale => {
            if (sale.items) {
                sale.items.forEach(item => {
                    if (!productSales[item.productId]) {
                        productSales[item.productId] = { 
                            name: item.name, 
                            quantity: 0, 
                            revenue: 0,
                            unit: item.unit || 'ea'
                        };
                    }
                    productSales[item.productId].quantity += (item.quantity || 0);
                    productSales[item.productId].revenue += ((item.price || 0) * (item.quantity || 0));
                });
            }
        });

        const topProducts = Object.values(productSales)
            .sort((a, b) => b.quantity - a.quantity)
            .slice(0, 5);

        // 4. Monthly Trend (Daily for the last 30 days)
        const dailyRevenue = {};
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setHours(0, 0, 0, 0);
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 29); // Start from 30 days including today

        sales.forEach(sale => {
            const saleDate = new Date(sale.createdAt);
            if (saleDate >= thirtyDaysAgo) {
                const dateKey = saleDate.toISOString().split('T')[0];
                if (!dailyRevenue[dateKey]) dailyRevenue[dateKey] = 0;
                dailyRevenue[dateKey] += (sale.totalAmount || 0);
            }
        });

        const trend = Array.from({ length: 30 }, (_, i) => {
            const d = new Date(thirtyDaysAgo);
            d.setDate(d.getDate() + i);
            const dateStr = d.toISOString().split('T')[0];
            return {
                date: dateStr,
                revenue: dailyRevenue[dateStr] || 0
            };
        });

        // 5. Customer Insights: Tracks how many active customers there are and total debt.
        const activeCustomers = customers.length;
        const totalOutstanding = customers.reduce((sum, c) => sum + (c.totalOutstanding || 0), 0);

        // 6. Total Purchases
        const totalPurchasesAmount = purchases.reduce((sum, p) => sum + (p.totalAmount || 0), 0);

        // Calculate Today's Sales
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const todaysSales = sales
            .filter(s => new Date(s.createdAt) >= today)
            .reduce((sum, s) => sum + (s.totalAmount || 0), 0);

        return {
            summary: {
                totalRevenue,
                totalProfit,
                todaysSales,
                totalCreditOutstanding: totalOutstanding,
                totalPurchases: totalPurchasesAmount,
                totalItemsSold,
                averageOrderValue: sales.length > 0 ? totalRevenue / sales.length : 0
            },
            inventory: {
                totalValue: totalStockValue,
                itemCount: products.length,
                lowStockCount: lowStockProducts,
                outOfStockProducts
            },
            topProducts,
            trend,
            customerInsights: {
                totalCustomers: activeCustomers,
                creditCustomers: customers.filter(c => (c.totalOutstanding || 0) > 0).length
            },
            timestamp: new Date().toISOString()
        };
    }
}

module.exports = { GetBusinessReport };
