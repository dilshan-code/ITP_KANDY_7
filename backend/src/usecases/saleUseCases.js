// Use Cases contain business logic for Sales.
// They don't know about HTTP or Firestore directly — they use the repository.

class GetAllSales {
    constructor(saleRepository) {
        this.saleRepository = saleRepository;
    }
    async execute() {
        return this.saleRepository.getAll();
    }
}

class GetSaleById {
    constructor(saleRepository) {
        this.saleRepository = saleRepository;
    }
    async execute(id) {
        return this.saleRepository.getById(id);
    }
}

class CreateSale {
    constructor(saleRepository) {
        this.saleRepository = saleRepository;
    }
    async execute(saleData) {
        // Business rule: must have at least one item
        if (!saleData.items || saleData.items.length === 0) {
            throw new Error('Sale must have at least one item');
        }
        // Business rule: credit sale must have customer name
        if (saleData.isCredit && !saleData.customerName) {
            throw new Error('Credit sale must have a customer name');
        }
        return this.saleRepository.create(saleData);
    }
}

class GetSalesSummaryByDateRange {
    constructor(saleRepository) {
        this.saleRepository = saleRepository;
    }
    async execute(from, to) {
        if (!from || !to) throw new Error('from and to dates are required');
        return this.saleRepository.getSummaryByDateRange(from, to);
    }
}

class GetTotalRevenue {
    constructor(saleRepository) {
        this.saleRepository = saleRepository;
    }
    async execute() {
        return this.saleRepository.getTotalRevenue();
    }
}

module.exports = {
    GetAllSales,
    GetSaleById,
    CreateSale,
    GetSalesSummaryByDateRange,
    GetTotalRevenue,
};
