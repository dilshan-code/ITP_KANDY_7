const { GetBusinessReport } = require('../src/usecases/reportUseCases');

describe('Report Use Cases', () => {
    let mockSaleRepository;
    let mockPurchaseRepository;
    let mockProductRepository;
    let mockCustomerRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        const today = new Date().toISOString();
        const yesterday = new Date(Date.now() - 86400000).toISOString();

        mockSaleRepository = {
            getAll: jest.fn().mockResolvedValue([
                {
                    id: 'sale1', totalAmount: 1000, createdAt: today,
                    items: [{ productId: 'p1', name: 'Rice', quantity: 5, price: 200 }]
                },
                {
                    id: 'sale2', totalAmount: 600, createdAt: yesterday,
                    items: [{ productId: 'p2', name: 'Sugar', quantity: 3, price: 200 }]
                },
                {
                    id: 'sale3', totalAmount: 400, createdAt: today,
                    items: [{ productId: 'p1', name: 'Rice', quantity: 2, price: 200 }]
                }
            ]),
            getTotalRevenue: jest.fn().mockResolvedValue(2000),
            getTotalRevenueByDateRange: jest.fn().mockImplementation((id, start, end) => {
                const todayPrefix = new Date().toISOString().split('T')[0];
                return start.includes(todayPrefix) ? Promise.resolve(1400) : Promise.resolve(2000);
            }),
            getAllByDateRange: jest.fn().mockResolvedValue([
                {
                    id: 'sale1', totalAmount: 1000, createdAt: today,
                    items: [{ productId: 'p1', name: 'Rice', quantity: 5, price: 200 }]
                },
                {
                    id: 'sale2', totalAmount: 600, createdAt: yesterday,
                    items: [{ productId: 'p2', name: 'Sugar', quantity: 3, price: 200 }]
                },
                {
                    id: 'sale3', totalAmount: 400, createdAt: today,
                    items: [{ productId: 'p1', name: 'Rice', quantity: 2, price: 200 }]
                }
            ]),
        };

        mockPurchaseRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'pur1', totalAmount: 3000, items: [] }
            ]),
            getTotalPurchases: jest.fn().mockResolvedValue(3000),
        };

        mockProductRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'p1', name: 'Rice', sellingPrice: 200, purchasePrice: 150, stockQuantity: 50, minimumStockLevel: 10 },
                { id: 'p2', name: 'Sugar', sellingPrice: 200, purchasePrice: 120, stockQuantity: 3, minimumStockLevel: 5 },
                { id: 'p3', name: 'Tea', sellingPrice: 300, purchasePrice: 250, stockQuantity: 0, minimumStockLevel: 5 }
            ]),
            getLowStockCount: jest.fn().mockResolvedValue(2),
        };

        mockCustomerRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'c1', name: 'Customer A', totalOutstanding: 1500 },
                { id: 'c2', name: 'Customer B', totalOutstanding: 0 },
                { id: 'c3', name: 'Customer C', totalOutstanding: 500 },
            ]),
            getTotalOutstanding: jest.fn().mockResolvedValue(2000),
        };
    });

    describe('GetBusinessReport', () => {
        let getReport;
        beforeEach(() => {
            getReport = new GetBusinessReport(mockSaleRepository, mockPurchaseRepository, mockProductRepository, mockCustomerRepository);
        });

        test('should throw if ownerId is missing', async () => {
            await expect(getReport.execute(null))
                .rejects.toThrow('Owner ID is required for report generation');
        });

        test('should calculate total revenue correctly', async () => {
            const report = await getReport.execute(ownerId);
            // 1000 + 600 + 400 = 2000
            expect(report.summary.totalRevenue).toBe(2000);
        });

        test('should calculate total items sold correctly', async () => {
            const report = await getReport.execute(ownerId);
            // 5 + 3 + 2 = 10
            expect(report.summary.totalItemsSold).toBe(10);
        });

        test('should calculate total profit correctly', async () => {
            const report = await getReport.execute(ownerId);
            // Cost: (5*150) + (3*120) + (2*150) = 750 + 360 + 300 = 1410
            // Profit: 2000 - 1410 = 590
            expect(report.summary.totalProfit).toBe(590);
        });

        test('should calculate today sales correctly', async () => {
            const report = await getReport.execute(ownerId);
            // sale1 (1000) + sale3 (400) = 1400
            expect(report.summary.todaysSales).toBe(1400);
        });

        test('should calculate average order value', async () => {
            const report = await getReport.execute(ownerId);
            // 2000 / 3 = 666.67
            expect(report.summary.averageOrderValue).toBeCloseTo(666.67, 1);
        });

        test('should identify inventory health metrics', async () => {
            const report = await getReport.execute(ownerId);
            // Low stock: Sugar (3 <= 5), Tea (0 <= 5) = 2
            expect(report.inventory.lowStockCount).toBe(2);
            // Out of stock: Tea (0) = 1
            expect(report.inventory.outOfStockProducts).toBe(1);
            expect(report.inventory.itemCount).toBe(3);
        });

        test('should calculate total inventory value', async () => {
            const report = await getReport.execute(ownerId);
            // (50*200) + (3*200) + (0*300) = 10000 + 600 + 0 = 10600
            expect(report.inventory.totalValue).toBe(10600);
        });

        test('should produce top products sorted by quantity sold', async () => {
            const report = await getReport.execute(ownerId);
            expect(report.topProducts).toHaveLength(2);
            // Rice sold 7 (5+2), Sugar sold 3
            expect(report.topProducts[0].name).toBe('Rice');
            expect(report.topProducts[0].quantity).toBe(7);
            expect(report.topProducts[1].name).toBe('Sugar');
            expect(report.topProducts[1].quantity).toBe(3);
        });

        test('should generate 30-day trend', async () => {
            const report = await getReport.execute(ownerId);
            expect(report.trend).toHaveLength(30);
            // Each trend entry should have date and revenue
            expect(report.trend[0]).toHaveProperty('date');
            expect(report.trend[0]).toHaveProperty('revenue');
        });

        test('should calculate customer insights', async () => {
            const report = await getReport.execute(ownerId);
            expect(report.customerInsights.totalCustomers).toBe(3);
            // Credit customers: A (1500), C (500) = 2
            expect(report.customerInsights.creditCustomers).toBe(2);
        });

        test('should include total credit outstanding', async () => {
            const report = await getReport.execute(ownerId);
            // 1500 + 0 + 500 = 2000
            expect(report.summary.totalCreditOutstanding).toBe(2000);
        });

        test('should include total purchases amount', async () => {
            const report = await getReport.execute(ownerId);
            expect(report.summary.totalPurchases).toBe(3000);
        });

        test('should include timestamp', async () => {
            const report = await getReport.execute(ownerId);
            expect(report).toHaveProperty('timestamp');
        });

        test('should handle empty data correctly', async () => {
            mockSaleRepository.getAllByDateRange.mockResolvedValue([]);
            mockSaleRepository.getTotalRevenue.mockResolvedValue(0);
            mockSaleRepository.getTotalRevenueByDateRange.mockResolvedValue(0);
            mockPurchaseRepository.getTotalPurchases.mockResolvedValue(0);
            mockProductRepository.getAll.mockResolvedValue([]);
            mockProductRepository.getLowStockCount.mockResolvedValue(0);
            mockCustomerRepository.getAll.mockResolvedValue([]);
            mockCustomerRepository.getTotalOutstanding.mockResolvedValue(0);

            const report = await getReport.execute(ownerId);
            expect(report.summary.totalRevenue).toBe(0);
            expect(report.summary.totalProfit).toBe(0);
            expect(report.summary.totalItemsSold).toBe(0);
            expect(report.summary.averageOrderValue).toBe(0);
            expect(report.inventory.itemCount).toBe(0);
            expect(report.topProducts).toHaveLength(0);
            expect(report.customerInsights.totalCustomers).toBe(0);
        });
    });
});
