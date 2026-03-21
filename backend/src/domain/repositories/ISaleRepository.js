/**
 * Interface for Sale Repository.
 * Defines the "contract" — any concrete implementation MUST provide
 * logic for all these functions.
 */
class ISaleRepository {
    async getAll() { throw new Error('Not implemented'); }
    async getById(id) { throw new Error('Not implemented'); }
    async create(saleData) { throw new Error('Not implemented'); }
    async getSummaryByDateRange(from, to) { throw new Error('Not implemented'); }
    async getTotalRevenue() { throw new Error('Not implemented'); }
}

module.exports = ISaleRepository;
