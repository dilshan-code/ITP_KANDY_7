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

        sales.forEach(sale => {
            totalRevenue += sale.totalAmount || 0;
            totalItemsSold += sale.items ? sale.items.reduce((sum, item) => sum + (item.quantity || 0), 0) : 0;
        });

        // 2. Inventory Health: Identifies products that are running low or out of stock.
        const lowStockProducts = products.filter(p => p.stock <= (p.lowStockThreshold || 5)).length;
        const outOfStockProducts = products.filter(p => p.stock <= 0).length;
        const totalStockValue = products.reduce((sum, p) => sum + (p.stock * (p.sellingPrice || 0)), 0);

        // 3. Top Selling Products: Ranks items based on how many have been sold.
        const productSales = {};
        sales.forEach(sale => {
            if (sale.items) {
                sale.items.forEach(item => {
                    if (!productSales[item.productId]) {
                        productSales[item.productId] = { 
                            name: item.name, 
                            quantity: 0, 
                            revenue: 0 
                        };
                    }
                    productSales[item.productId].quantity += (item.quantity || 0);
                    productSales[item.productId].revenue += (item.price * (item.quantity || 0));
                });
            }
        });

        const topProducts = Object.values(productSales)
            .sort((a, b) => b.quantity - a.quantity)
            .slice(0, 5);

        // 4. Customer Insights: Tracks how many active customers there are and total debt.
        const activeCustomers = customers.length;
        const totalOutstanding = customers.reduce((sum, c) => sum + (c.outstandingBalance || 0), 0);

        // 5. Total Purchases
        const totalPurchasesAmount = purchases.reduce((sum, p) => sum + (p.totalAmount || 0), 0);

        return {
            summary: {
                totalRevenue,
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
            customerInsights: {
                totalCustomers: activeCustomers,
                creditCustomers: customers.filter(c => (c.outstandingBalance || 0) > 0).length
            },
            timestamp: new Date().toISOString()
        };
    }
}

module.exports = { GetBusinessReport };
