const { GetAllPurchases, GetPurchaseById, CreatePurchase, GetPurchasesBySupplier, UpdatePurchase, DeletePurchase } = require('../src/usecases/purchaseUseCases');

jest.mock('../src/config/firebaseAdmin', () => ({
    db: {
        runTransaction: jest.fn(async (callback) => {
            const mockTransaction = { 
                get: jest.fn(), 
                set: jest.fn(), 
                update: jest.fn(), 
                delete: jest.fn() 
            };
            return callback(mockTransaction);
        }),
    },
}));

describe('Purchase Use Cases', () => {
    let mockPurchaseRepository;
    let mockProductRepository;
    let mockSupplierRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        mockPurchaseRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'pur1', supplierId: 's1', totalAmount: 5000, items: [{ productId: 'p1', quantity: 10 }] }
            ]),
            getById: jest.fn().mockImplementation((id) => Promise.resolve({
                id, supplierId: 's1', totalAmount: 5000,
                items: [{ productId: 'p1', quantity: 10 }, { productId: 'p2', quantity: 5 }]
            })),
            getBySupplier: jest.fn().mockResolvedValue([{ id: 'pur1', supplierId: 's1' }]),
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'new-pur1', ...data })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
            delete: jest.fn().mockResolvedValue(true),
        };
        mockProductRepository = {
            getById: jest.fn().mockImplementation((id) => Promise.resolve({ id, name: 'Product', stockQuantity: 20 })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
        };
        mockSupplierRepository = {
            getById: jest.fn().mockImplementation((id) => Promise.resolve({ id, name: 'Supplier', totalPayable: 1000 })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
        };
    });

    // ========== GetAllPurchases ==========
    describe('GetAllPurchases', () => {
        test('should return all purchases', async () => {
            const useCase = new GetAllPurchases(mockPurchaseRepository);
            const result = await useCase.execute(ownerId);
            expect(result).toHaveLength(1);
            expect(mockPurchaseRepository.getAll).toHaveBeenCalledWith(ownerId, undefined, undefined);
        });
    });

    // ========== GetPurchaseById ==========
    describe('GetPurchaseById', () => {
        test('should return a purchase by ID', async () => {
            const useCase = new GetPurchaseById(mockPurchaseRepository);
            const result = await useCase.execute('pur1', ownerId);
            expect(result.supplierId).toBe('s1');
        });
    });

    // ========== CreatePurchase ==========
    describe('CreatePurchase', () => {
        let createPurchase;
        beforeEach(() => { createPurchase = new CreatePurchase(mockPurchaseRepository, mockProductRepository, mockSupplierRepository); });

        test('should create a purchase and increase stock for each item', async () => {
            const data = {
                supplierId: 's1',
                totalAmount: 5000,
                items: [{ productId: 'p1', quantity: 5 }, { productId: 'p2', quantity: 3 }]
            };
            const result = await createPurchase.execute(data, ownerId);
            expect(result).toHaveProperty('id', 'new-pur1');
            expect(mockPurchaseRepository.create).toHaveBeenCalledWith({ ...data, ownerId }, expect.anything());
            // Stock should be increased: 20 + 5 = 25, 20 + 3 = 23
            expect(mockProductRepository.update).toHaveBeenCalledWith('p1', { stockQuantity: 25 }, ownerId, expect.anything());
            expect(mockProductRepository.update).toHaveBeenCalledWith('p2', { stockQuantity: 23 }, ownerId, expect.anything());
            // Supplier balance should be updated
            expect(mockSupplierRepository.getById).toHaveBeenCalledWith('s1', ownerId, expect.anything());
            expect(mockSupplierRepository.update).toHaveBeenCalledWith('s1', { totalPayable: 1000 + (data.totalAmount || 0) }, ownerId, expect.anything());
        });

        test('should throw if data or ownerId is missing', async () => {
            await expect(createPurchase.execute(null, ownerId)).rejects.toThrow('Purchase data and Owner ID are required');
            await expect(createPurchase.execute({ supplierId: 's1' }, null)).rejects.toThrow('Purchase data and Owner ID are required');
        });

        test('should handle purchase with no items', async () => {
            const data = { supplierId: 's1', items: [] };
            const result = await createPurchase.execute(data, ownerId);
            expect(result).toHaveProperty('id');
            expect(mockProductRepository.update).not.toHaveBeenCalled();
        });

        test('should skip items without productId', async () => {
            const data = { supplierId: 's1', items: [{ quantity: 5 }] };
            await createPurchase.execute(data, ownerId);
            expect(mockProductRepository.getById).not.toHaveBeenCalled();
        });

        test('should handle product not found gracefully', async () => {
            mockProductRepository.getById.mockResolvedValue(null);
            const data = { supplierId: 's1', items: [{ productId: 'p-unknown', quantity: 5 }] };
            await createPurchase.execute(data, ownerId);
            expect(mockProductRepository.update).not.toHaveBeenCalled();
        });
    });

    // ========== GetPurchasesBySupplier ==========
    describe('GetPurchasesBySupplier', () => {
        test('should return purchases by supplier', async () => {
            const useCase = new GetPurchasesBySupplier(mockPurchaseRepository);
            const result = await useCase.execute('s1', ownerId);
            expect(result).toHaveLength(1);
            expect(mockPurchaseRepository.getBySupplier).toHaveBeenCalledWith('s1', ownerId, undefined, undefined);
        });
    });

    // ========== UpdatePurchase ==========
    describe('UpdatePurchase', () => {
        test('should update a purchase', async () => {
            const useCase = new UpdatePurchase(mockPurchaseRepository);
            const result = await useCase.execute('pur1', { notes: 'Updated' }, ownerId);
            expect(result.notes).toBe('Updated');
        });
    });

    // ========== DeletePurchase ==========
    describe('DeletePurchase', () => {
        let deletePurchase;
        beforeEach(() => { deletePurchase = new DeletePurchase(mockPurchaseRepository, mockProductRepository, mockSupplierRepository); });

        test('should delete purchase and revert stock for each item', async () => {
            const result = await deletePurchase.execute('pur1', ownerId);
            expect(result).toBe(true);
            // Stock should be reverted: 20 - 10 = 10, 20 - 5 = 15
            expect(mockProductRepository.update).toHaveBeenCalledWith('p1', { stockQuantity: 10 }, ownerId, expect.anything());
            expect(mockProductRepository.update).toHaveBeenCalledWith('p2', { stockQuantity: 15 }, ownerId, expect.anything());
            // Supplier balance should be reverted
            expect(mockSupplierRepository.update).toHaveBeenCalledWith('s1', { totalPayable: 1000 - 5000 < 0 ? 0 : 1000 - 5000 }, ownerId, expect.anything());
            expect(mockPurchaseRepository.delete).toHaveBeenCalledWith('pur1', ownerId, expect.anything());
        });

        test('should throw if ID or ownerId is missing', async () => {
            await expect(deletePurchase.execute(null, ownerId)).rejects.toThrow('Purchase ID and Owner ID are required');
            await expect(deletePurchase.execute('pur1', null)).rejects.toThrow('Purchase ID and Owner ID are required');
        });

        test('should return false if purchase not found', async () => {
            mockPurchaseRepository.getById.mockResolvedValue(null);
            const result = await deletePurchase.execute('unknown', ownerId);
            expect(result).toBe(false);
        });

        test('should not reduce stock below 0 on revert', async () => {
            mockProductRepository.getById.mockResolvedValue({ id: 'p1', stockQuantity: 3 });
            mockPurchaseRepository.getById.mockResolvedValue({
                id: 'pur1', items: [{ productId: 'p1', quantity: 10 }]
            });
            await deletePurchase.execute('pur1', ownerId);
            // max(0, 3 - 10) = 0
            expect(mockProductRepository.update).toHaveBeenCalledWith('p1', { stockQuantity: 0 }, ownerId, expect.anything());
        });
    });
});
