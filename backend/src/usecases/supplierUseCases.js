const { isValidPhone, isValidEmail } = require('../utils/validationUtils');

// Retrieves all business partners who supply stock to the shop.
class GetAllSuppliers {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute() { return this.supplierRepository.getAll(); }
}

class GetSupplierById {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(id) { return this.supplierRepository.getById(id); }
}

// Registers a new supplier in the system.
class CreateSupplier {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(supplierData) {
        if (!supplierData.name || supplierData.name.trim() === '') {
            throw new Error('Supplier name is required');
        }
        if (!supplierData.phone || !isValidPhone(supplierData.phone)) {
            throw new Error('Valid phone number is required');
        }
        if (supplierData.email && !isValidEmail(supplierData.email)) {
            throw new Error('Invalid email format');
        }
        return this.supplierRepository.create(supplierData);
    }
}

// Updates supplier details, like contact info or company name.
class UpdateSupplier {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(id, supplierData) {
        if (supplierData.name !== undefined && supplierData.name.trim() === '') {
            throw new Error('Supplier name cannot be empty');
        }
        if (supplierData.phone !== undefined && !isValidPhone(supplierData.phone)) {
            throw new Error('Valid phone number is required');
        }
        if (supplierData.email && !isValidEmail(supplierData.email)) {
            throw new Error('Invalid email format');
        }
        return this.supplierRepository.update(id, supplierData);
    }
}

class DeleteSupplier {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(id) { return this.supplierRepository.delete(id); }
}

module.exports = { GetAllSuppliers, GetSupplierById, CreateSupplier, UpdateSupplier, DeleteSupplier };
