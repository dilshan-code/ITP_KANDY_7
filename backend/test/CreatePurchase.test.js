const { CreatePurchase } = require('../src/usecases/purchaseUseCases');

describe('CreatePurchase Use Case', () => {
    let mockPurchaseRepository;
    let mockProductRepository;
    let createPurchase;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        mockPurchaseRepository = {
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'p1', ...data }))
        };
        mockProductRepository = {
            getById: jest.fn().mockImplementation((id, oid) => Promise.resolve({ id, name: 'Test Product', stockQuantity: 10, ownerId: oid })),
            update: jest.fn().mockImplementation((id, data, oid) => Promise.resolve({ id, ...data, ownerId: oid }))
        };
        createPurchase = new CreatePurchase(mockPurchaseRepository, mockProductRepository);
    });

    test('should create a purchase and update product stock', async () => {
        const purchaseData = {
            supplierId: 's1',
            supplierName: 'Test Supplier',
            items: [
                { productId: 'prod1', quantity: 5, costPrice: 100 }
            ],
            notes: 'Test purchase'
        };

        const result = await createPurchase.execute(purchaseData, ownerId);

        expect(mockPurchaseRepository.create).toHaveBeenCalledWith({ ...purchaseData, ownerId });
        expect(mockProductRepository.getById).toHaveBeenCalledWith('prod1', ownerId);
        expect(mockProductRepository.update).toHaveBeenCalledWith('prod1', { stockQuantity: 15 }, ownerId);
        expect(result.notes).toBe('Test purchase');
    });

    test('should handle multiple items and update stock for each', async () => {
        const purchaseData = {
          supplierId: 's1',
          items: [
              { productId: 'prod1', quantity: 5 },
              { productId: 'prod2', quantity: 3 }
          ]
        };

        await createPurchase.execute(purchaseData, ownerId);

        expect(mockProductRepository.update).toHaveBeenCalledWith('prod1', { stockQuantity: 15 }, ownerId);
        expect(mockProductRepository.update).toHaveBeenCalledWith('prod2', { stockQuantity: 13 }, ownerId);
    });
});
