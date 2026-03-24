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
    async execute(supplierData) { return this.supplierRepository.create(supplierData); }
}

// Updates supplier details, like contact info or company name.
class UpdateSupplier {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(id, supplierData) { return this.supplierRepository.update(id, supplierData); }
}

class DeleteSupplier {
    constructor(supplierRepository) { this.supplierRepository = supplierRepository; }
    async execute(id) { return this.supplierRepository.delete(id); }
}

module.exports = { GetAllSuppliers, GetSupplierById, CreateSupplier, UpdateSupplier, DeleteSupplier };
