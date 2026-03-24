class ICustomerRepository {
    async getAll() { throw new Error('Not implemented'); }
    async getById(id) { throw new Error('Not implemented'); }
    async create(customerData) { throw new Error('Not implemented'); }
    async update(id, customerData) { throw new Error('Not implemented'); }
    async delete(id) { throw new Error('Not implemented'); }
}

module.exports = ICustomerRepository;
