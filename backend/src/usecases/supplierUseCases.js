const { isValidPhone, isValidEmail } = require('../utils/validationUtils');

// Retrieves all business partners who supply stock to the shop.
class GetAllSuppliers {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(ownerId, limit, lastId) { return this.supplierRepository.getAll(ownerId, limit, lastId); }
}

class GetSupplierById {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(id, ownerId) { return this.supplierRepository.getById(id, ownerId); }
}

// Registers a new supplier in the system.
class CreateSupplier {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(supplierData, ownerId) {
        if (!supplierData || !ownerId) throw new Error('Supplier data and Owner ID are required');
        if (!supplierData.name || supplierData.name.trim() === '') {
            throw new Error('Supplier name is required');
        }
        if (!supplierData.phone || !isValidPhone(supplierData.phone)) {
            throw new Error('Valid phone number is required');
        }
        if (supplierData.email && !isValidEmail(supplierData.email)) {
            throw new Error('Invalid email format');
        }
        return this.supplierRepository.create({ ...supplierData, ownerId });
    }
}

// Updates supplier details, like contact info or company name.
class UpdateSupplier {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(id, supplierData, ownerId) {
        if (!id || !ownerId) throw new Error('Supplier ID and Owner ID are required');
        if (supplierData.name !== undefined && supplierData.name.trim() === '') {
            throw new Error('Supplier name cannot be empty');
        }
        if (supplierData.phone !== undefined && !isValidPhone(supplierData.phone)) {
            throw new Error('Valid phone number is required');
        }
        if (supplierData.email && !isValidEmail(supplierData.email)) {
            throw new Error('Invalid email format');
        }
        return this.supplierRepository.update(id, supplierData, ownerId);
    }
}

class DeleteSupplier {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(id, ownerId) { 
        if (!id || !ownerId) throw new Error('Supplier ID and Owner ID are required');
        
        const supplier = await this.supplierRepository.getById(id, ownerId);
        if (!supplier) return false;

        if (supplier.totalPayable > 0) {
            throw new Error(`Cannot delete supplier with an outstanding balance of Rs ${supplier.totalPayable}. Please settle all payments first.`);
        }

        return this.supplierRepository.delete(id, ownerId); 
    }
}

// Global aggregation for all suppliers owned by this user.
class GetSupplierSummary {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const totalPayable = await this.supplierRepository.getTotalPayable(ownerId);
        
        // We can also fetch the count of active suppliers
        const suppliers = await this.supplierRepository.getAll(ownerId);
        const activeCount = suppliers.filter(s => s.status === 'active').length;

        return {
            totalPayable: totalPayable || 0,
            activeCount: activeCount
        };
    }
}

module.exports = { GetAllSuppliers, GetSupplierById, CreateSupplier, UpdateSupplier, DeleteSupplier, GetSupplierSummary };
