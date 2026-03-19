class ICreditTransactionRepository {
    async getAll() { throw new Error('Not implemented'); }
    async getByCustomer(customerId) { throw new Error('Not implemented'); }
    async create(transactionData) { throw new Error('Not implemented'); }
}

module.exports = ICreditTransactionRepository;
