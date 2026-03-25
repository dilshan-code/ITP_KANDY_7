// Mock the Firebase Admin config module BEFORE importing the use cases
jest.mock('../src/config/firebaseAdmin', () => ({
    db: {
        runTransaction: jest.fn(async (callback) => {
            const mockTransaction = {
                get: jest.fn().mockResolvedValue({ docs: [], exists: true, data: () => ({}) }),
                set: jest.fn(),
                update: jest.fn(),
                delete: jest.fn(),
            };
            return callback(mockTransaction);
        }),
        collection: jest.fn().mockReturnValue({
            doc: jest.fn().mockReturnValue({ ref: 'mock-ref' }),
            where: jest.fn().mockReturnThis(),
            get: jest.fn().mockResolvedValue({ docs: [] }),
        }),
    },
}));

const { GetAllSales, GetSaleById, CreateSale, GetSalesByCustomer, DeleteSale, UpdateSale } = require('../src/usecases/saleUseCases');

describe('Sale Use Cases', () => {
    let mockSaleRepository;
    let mockProductRepository;
    let mockCustomerRepository;
    let mockCreditTransactionRepository;
    let mockNotificationRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        jest.clearAllMocks();

        mockSaleRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'sale1', totalAmount: 1000, paymentMethod: 'cash', items: [{ productId: 'p1', quantity: 2 }], createdAt: new Date().toISOString() }
            ]),
            getById: jest.fn().mockImplementation((id, owId, txn) => Promise.resolve({
                id, totalAmount: 500, paymentMethod: 'credit', customerId: 'c1',
                items: [{ productId: 'p1', quantity: 3, name: 'Rice' }],
                createdAt: new Date().toISOString()
            })),
            getByCustomer: jest.fn().mockResolvedValue([{ id: 'sale1', customerId: 'c1' }]),
            create: jest.fn().mockImplementation((data, txn) => Promise.resolve({ id: 'new-sale1', ...data })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
        };

        mockProductRepository = {
            getById: jest.fn().mockImplementation((id, owId, txn) => Promise.resolve({
                id, name: 'Rice', stockQuantity: 50, sellingPrice: 200, notifyOutOfStock: true
            })),
            update: jest.fn().mockResolvedValue(true),
        };

        mockCustomerRepository = {
            getById: jest.fn().mockImplementation((id, owId, txn) => Promise.resolve({
                id, name: 'Customer A', totalOutstanding: 500, creditLimit: 5000, status: 'active'
            })),
            update: jest.fn().mockResolvedValue(true),
        };

        mockCreditTransactionRepository = {
            create: jest.fn().mockImplementation((data, txn) => Promise.resolve({ id: 'ct1', ...data })),
        };

        mockNotificationRepository = {
            create: jest.fn().mockImplementation((data, txn) => Promise.resolve({ id: 'notif1', ...data })),
        };
    });

    // ========== GetAllSales ==========
    describe('GetAllSales', () => {
        test('should return all sales', async () => {
            const useCase = new GetAllSales(mockSaleRepository);
            const result = await useCase.execute(ownerId, undefined, undefined);
            expect(result).toHaveLength(1);
        });
    });

    // ========== GetSaleById ==========
    describe('GetSaleById', () => {
        test('should return a sale by ID', async () => {
            const useCase = new GetSaleById(mockSaleRepository);
            const result = await useCase.execute('sale1', ownerId);
            expect(result.totalAmount).toBe(500);
        });
    });

    // ========== CreateSale ==========
    describe('CreateSale', () => {
        let createSale;
        beforeEach(() => {
            createSale = new CreateSale(
                mockSaleRepository, mockProductRepository, mockCustomerRepository,
                mockCreditTransactionRepository, mockNotificationRepository
            );
        });

        test('should throw if data or ownerId is missing', async () => {
            await expect(createSale.execute(null, ownerId)).rejects.toThrow('Sale data and Owner ID are required');
            await expect(createSale.execute({ items: [] }, null)).rejects.toThrow('Sale data and Owner ID are required');
        });

        test('should create a cash sale and deduct stock', async () => {
            const saleData = {
                paymentMethod: 'cash',
                totalAmount: 400,
                items: [{ productId: 'p1', quantity: 2 }]
            };
            const result = await createSale.execute(saleData, ownerId);
            expect(result).toHaveProperty('id', 'new-sale1');
            // Stock: 50 - 2 = 48
            expect(mockProductRepository.update).toHaveBeenCalledWith(
                'p1', { stockQuantity: 48 }, ownerId, expect.anything()
            );
        });

        test('should create a credit sale and update customer balance', async () => {
            const saleData = {
                paymentMethod: 'credit',
                totalAmount: 1000,
                customerId: 'c1',
                items: [{ productId: 'p1', quantity: 5 }]
            };
            await createSale.execute(saleData, ownerId);

            // Customer balance: 500 + 1000 = 1500
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { totalOutstanding: 1500 }, ownerId, expect.anything()
            );
            // Should create a credit transaction record
            expect(mockCreditTransactionRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    ownerId,
                    customerId: 'c1',
                    type: 'credit',
                    amount: 1000
                }),
                expect.anything()
            );
        });

        test('should trigger credit limit exceeded notification', async () => {
            // Customer has outstanding 500, credit limit 5000, adding 5000 = 5500 > 5000
            const saleData = {
                paymentMethod: 'credit',
                totalAmount: 5000,
                customerId: 'c1',
                items: [{ productId: 'p1', quantity: 1 }]
            };
            await createSale.execute(saleData, ownerId);
            expect(mockNotificationRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'alert',
                    title: 'Credit Limit Exceeded',
                }),
                expect.anything()
            );
        });

        test('should handle settlement sale (partial payment)', async () => {
            // Partial settlement: items are present, so totalAmount is used as-is
            const saleData = {
                paymentMethod: 'settlement',
                totalAmount: 200,
                customerId: 'c1',
                items: [{ productId: 'p1', quantity: 1 }]
            };
            await createSale.execute(saleData, ownerId);

            // 500 - 200 = 300, status stays 'active'
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { totalOutstanding: 300, status: 'active' }, ownerId, expect.anything()
            );
            expect(mockCreditTransactionRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'payment',
                    title: 'Partial Credit Payment'
                }),
                expect.anything()
            );
        });

        test('should handle full settlement and set status to paid', async () => {
            // Full settlement: totalAmount matches customer's outstanding (500)
            const saleData = {
                paymentMethod: 'settlement',
                customerId: 'c1',
                items: []  // No items = full settlement
            };
            await createSale.execute(saleData, ownerId);

            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', { totalOutstanding: 0, status: 'paid' }, ownerId, expect.anything()
            );
            expect(mockCreditTransactionRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'payment',
                    title: 'Full Balance Settlement'
                }),
                expect.anything()
            );
        });

        test('should trigger out-of-stock notification', async () => {
            mockProductRepository.getById.mockResolvedValue({
                id: 'p1', name: 'Rice', stockQuantity: 2, notifyOutOfStock: true
            });
            const saleData = {
                paymentMethod: 'cash',
                totalAmount: 400,
                items: [{ productId: 'p1', quantity: 2 }]
            };
            await createSale.execute(saleData, ownerId);
            // Stock: max(0, 2-2) = 0 → should trigger notification
            expect(mockNotificationRepository.create).toHaveBeenCalledWith(
                expect.objectContaining({
                    type: 'warning',
                    title: 'Product Out of Stock',
                }),
                expect.anything()
            );
        });

        test('should NOT trigger out-of-stock notification if disabled', async () => {
            mockProductRepository.getById.mockResolvedValue({
                id: 'p1', name: 'Rice', stockQuantity: 2, notifyOutOfStock: false
            });
            const saleData = {
                paymentMethod: 'cash',
                totalAmount: 400,
                items: [{ productId: 'p1', quantity: 2 }]
            };
            await createSale.execute(saleData, ownerId);
            expect(mockNotificationRepository.create).not.toHaveBeenCalled();
        });

        test('should handle sale with no items (e.g. settlement only)', async () => {
            const saleData = {
                paymentMethod: 'cash',
                totalAmount: 100,
                items: []
            };
            const result = await createSale.execute(saleData, ownerId);
            expect(result).toHaveProperty('id');
            expect(mockProductRepository.getById).not.toHaveBeenCalled();
        });
    });

    // ========== GetSalesByCustomer ==========
    describe('GetSalesByCustomer', () => {
        test('should return sales by customer', async () => {
            const useCase = new GetSalesByCustomer(mockSaleRepository);
            const result = await useCase.execute('c1', ownerId, undefined, undefined);
            expect(result).toHaveLength(1);
        });
    });

    // ========== DeleteSale ==========
    describe('DeleteSale', () => {
        let deleteSale;
        beforeEach(() => {
            deleteSale = new DeleteSale(mockSaleRepository, mockProductRepository, mockCustomerRepository, mockCreditTransactionRepository);
        });

        test('should throw if ID or ownerId missing', async () => {
            await expect(deleteSale.execute(null, ownerId)).rejects.toThrow('Sale ID and Owner ID are required');
            await expect(deleteSale.execute('sale1', null)).rejects.toThrow('Sale ID and Owner ID are required');
        });

        test('should return false if sale not found', async () => {
            mockSaleRepository.getById.mockResolvedValue(null);
            const result = await deleteSale.execute('not-found', ownerId);
            expect(result).toBe(false);
        });

        test('should delete a credit sale and revert stock + customer balance', async () => {
            const result = await deleteSale.execute('sale1', ownerId);
            expect(result).toBe(true);

            // Product stock reverted: 50 + 3 = 53
            expect(mockProductRepository.update).toHaveBeenCalledWith(
                'p1', { stockQuantity: 53 }, ownerId, expect.anything()
            );
            // Customer balance reverted: max(0, 500 - 500) = 0
            expect(mockCustomerRepository.update).toHaveBeenCalledWith(
                'c1', expect.objectContaining({ totalOutstanding: 0 }), ownerId, expect.anything()
            );
        });

        test('should handle cash sale deletion (no customer revert)', async () => {
            mockSaleRepository.getById.mockResolvedValue({
                id: 'sale2', totalAmount: 300, paymentMethod: 'cash',
                items: [{ productId: 'p1', quantity: 2 }]
            });
            const result = await deleteSale.execute('sale2', ownerId);
            expect(result).toBe(true);
            expect(mockCustomerRepository.getById).not.toHaveBeenCalled();
        });
    });

    // ========== UpdateSale ==========
    describe('UpdateSale', () => {
        test('should update a sale', async () => {
            const useCase = new UpdateSale(mockSaleRepository, mockProductRepository, mockCustomerRepository, mockCreditTransactionRepository);
            const result = await useCase.execute('sale1', { notes: 'Updated' }, ownerId);
            expect(result.notes).toBe('Updated');
        });
    });
});
