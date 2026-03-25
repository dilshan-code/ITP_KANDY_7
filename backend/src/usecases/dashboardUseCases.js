
class GetDashboardData {
    constructor(repositories) {
        this.productRepository = repositories.productRepository;
        this.saleRepository = repositories.saleRepository;
        this.purchaseRepository = repositories.purchaseRepository;
        this.customerRepository = repositories.customerRepository;
        this.supplierRepository = repositories.supplierRepository;
    }

    async execute(ownerId) {
        // Run all optimized aggregation queries in parallel for maximum speed
        const [
            todaysSales,
            lowStockCount,
            customerCredit,
            toSuppliers,
            totalItemsInStock,
            recentSales,
            recentPurchases
        ] = await Promise.all([
            this.saleRepository.getTodayTotal(ownerId),
            this.productRepository.getLowStockCount(ownerId),
            this.customerRepository.getTotalOutstanding(ownerId),
            this.supplierRepository.getTotalPayable(ownerId),
            this.getTotalItemsInStock(ownerId),
            this.saleRepository.getAll(ownerId, 5), // Only get 5 newest sales
            this.purchaseRepository.getAll(ownerId, 5) // Only get 5 newest purchases
        ]);

        // Merge and sort the 5 overall most recent transactions for the dashboard timeline
        let allTxns = [];
        recentSales.forEach(s => {
            allTxns.push({
                id: s.id,
                type: s.paymentMethod === 'credit' ? 'credit' : 'order',
                title: s.paymentMethod === 'credit' ? 'Credit Sale' : `Sale #${s.id.substring(0, 5)}`,
                subtitle: s.customerName || 'Walk-in Customer',
                amount: s.totalAmount || 0,
                time: s.createdAt
            });
        });
        recentPurchases.forEach(p => {
            allTxns.push({
                id: p.id,
                type: 'purchase',
                title: `Purchase #${p.id.substring(0, 5)}`,
                subtitle: `Supplier: ${p.supplierName || 'Unknown'}`,
                amount: -(p.totalAmount || 0),
                time: p.purchaseDate || p.createdAt
            });
        });

        allTxns.sort((a, b) => new Date(b.time) - new Date(a.time));
        const recentTransactions = allTxns.slice(0, 5);

        return {
            todaysSales,
            lowStockCount,
            customerCredit,
            toSuppliers,
            totalItemsInStock,
            recentTransactions
        };
    }

    async getTotalItemsInStock(ownerId) {
        const { AggregateField } = require('firebase-admin/firestore');
        const snapshot = await this.productRepository.collection
            .where('ownerId', '==', ownerId)
            .aggregate({
                total: AggregateField.sum('stockQuantity')
            })
            .get();
        return snapshot.data().total;
    }
}

module.exports = { GetDashboardData };
