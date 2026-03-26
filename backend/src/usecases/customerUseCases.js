// Retrieves all customers registered in the shop.
class GetAllCustomers {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(ownerId, limit, lastId) { return this.customerRepository.getAll(ownerId, limit, lastId); }
}

class GetCustomerById {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(id, ownerId) { return this.customerRepository.getById(id, ownerId); }
}

// Adds a new customer profile to the database.
class CreateCustomer {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(customerData, ownerId) { 
        if (!customerData || !ownerId) throw new Error('Customer data and Owner ID are required');
        return this.customerRepository.create({ ...customerData, ownerId }); 
    }
}

// Updates existing customer information, such as their phone number or address.
class UpdateCustomer {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(id, customerData, ownerId) { 
        if (!id || !ownerId) throw new Error('Customer ID and Owner ID are required');
        return this.customerRepository.update(id, customerData, ownerId); 
    }
}

class DeleteCustomer {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(id, ownerId) { 
        if (!id || !ownerId) throw new Error('Customer ID and Owner ID are required');
        
        const customer = await this.customerRepository.getById(id, ownerId);
        if (!customer) return false;

        if (customer.totalOutstanding > 0) {
            throw new Error(`Cannot delete customer with an outstanding balance of Rs ${customer.totalOutstanding}. Please settle all debts first.`);
        }

        return this.customerRepository.delete(id, ownerId); 
    }
}

module.exports = { GetAllCustomers, GetCustomerById, CreateCustomer, UpdateCustomer, DeleteCustomer };
