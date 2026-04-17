const { DeleteOwner } = require('../src/usecases/authUseCases');

describe('Account Deletion Unit Test (Mocked)', () => {
    let repositories = {};
    const testOwnerId = 'test_owner_123';

    beforeEach(() => {
        // Create mock repositories with jest spy functions
        repositories = {
            ownerRepository: { delete: jest.fn().mockResolvedValue({ deletedCount: 1 }) },
            productRepository: { model: { deleteMany: jest.fn().mockResolvedValue({ deletedCount: 5 }) } },
            saleRepository: { model: { deleteMany: jest.fn().mockResolvedValue({ deletedCount: 10 }) } },
            purchaseRepository: { model: { deleteMany: jest.fn().mockResolvedValue({ deletedCount: 2 }) } },
            customerRepository: { model: { deleteMany: jest.fn().mockResolvedValue({ deletedCount: 3 }) } },
            supplierRepository: { model: { deleteMany: jest.fn().mockResolvedValue({ deletedCount: 1 }) } },
            creditTransactionRepository: { model: { deleteMany: jest.fn().mockResolvedValue({ deletedCount: 0 }) } },
            notificationRepository: { model: { deleteMany: jest.fn().mockResolvedValue({ deletedCount: 20 }) } },
            feedbackRepository: { model: { deleteMany: jest.fn().mockResolvedValue({ deletedCount: 1 }) } }
        };
    });

    test('DeleteOwner use case should call deleteMany on ALL related data repositories', async () => {
        const deleteOwner = new DeleteOwner(repositories);
        const result = await deleteOwner.execute(testOwnerId);

        // Verify result
        expect(result.deletedCount).toBe(1);

        // Verify that EVERY repository's deleteMany was called with the correct ownerId
        expect(repositories.productRepository.model.deleteMany).toHaveBeenCalledWith({ ownerId: testOwnerId });
        expect(repositories.saleRepository.model.deleteMany).toHaveBeenCalledWith({ ownerId: testOwnerId });
        expect(repositories.purchaseRepository.model.deleteMany).toHaveBeenCalledWith({ ownerId: testOwnerId });
        expect(repositories.customerRepository.model.deleteMany).toHaveBeenCalledWith({ ownerId: testOwnerId });
        expect(repositories.supplierRepository.model.deleteMany).toHaveBeenCalledWith({ ownerId: testOwnerId });
        expect(repositories.creditTransactionRepository.model.deleteMany).toHaveBeenCalledWith({ ownerId: testOwnerId });
        expect(repositories.notificationRepository.model.deleteMany).toHaveBeenCalledWith({ ownerId: testOwnerId });
        expect(repositories.feedbackRepository.model.deleteMany).toHaveBeenCalledWith({ ownerId: testOwnerId });

        // Verify owner record was deleted last
        expect(repositories.ownerRepository.delete).toHaveBeenCalledWith(testOwnerId);
        
        console.log('✅ Success: All 9 collections correctly targeted for deletion.');
    });
});
