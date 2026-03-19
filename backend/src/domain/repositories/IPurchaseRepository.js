class IPurchaseRepository {
    async getAll() { throw new Error('Not implemented'); }
    async getById(id) { throw new Error('Not implemented'); }
    async create(purchaseData) { throw new Error('Not implemented'); }
    async getBySupplier(supplierId) { throw new Error('Not implemented'); }
}

module.exports = IPurchaseRepository;
