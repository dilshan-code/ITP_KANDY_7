// Retrieves all customers registered in the shop.
class GetAllCustomers {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute() { return this.customerRepository.getAll(); }
}

class GetCustomerById {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(id) { return this.customerRepository.getById(id); }
}

// Adds a new customer profile to the database.
class CreateCustomer {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(customerData) { return this.customerRepository.create(customerData); }
}

// Updates existing customer information, such as their phone number or address.
class UpdateCustomer {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(id, customerData) { return this.customerRepository.update(id, customerData); }
}

class DeleteCustomer {
    constructor(customerRepository) { this.customerRepository = customerRepository; }
    async execute(id) { return this.customerRepository.delete(id); }
}

module.exports = { GetAllCustomers, GetCustomerById, CreateCustomer, UpdateCustomer, DeleteCustomer };
