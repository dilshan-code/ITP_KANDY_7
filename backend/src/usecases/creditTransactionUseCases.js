class GetAllCreditTransactions {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute() { return this.creditTransactionRepository.getAll(); }
}

// Retrieves a list of all debt/payment logs for a specific customer.
class GetCreditTransactionsByCustomer {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(customerId) { return this.creditTransactionRepository.getByCustomer(customerId); }
}

// Records a new credit (loan) or payment for a customer and updates their total balance.
class CreateCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }
    async execute(transactionData) { 
        // 1. Create the transaction
        const txn = await this.creditTransactionRepository.create(transactionData);

        // 2. Update customer balance and status
        if (transactionData.customerId) {
            const customer = await this.customerRepository.getById(transactionData.customerId);
            if (customer) {
                let newOutstanding = customer.totalOutstanding || 0;
                if (transactionData.type === 'credit') {
                    newOutstanding += transactionData.amount;
                } else if (transactionData.type === 'payment') {
                    newOutstanding -= transactionData.amount;
                }

                // If balance is 0 or less, we consider the debt 'paid'; otherwise, it's still 'active'.
                const newStatus = newOutstanding <= 0 ? 'paid' : 'active';
                
                await this.customerRepository.update(customer.id, { 
                    totalOutstanding: Math.max(0, newOutstanding),
                    status: newStatus 
                });
            }
        }
        return txn;
    }
}

class UpdateCreditTransaction {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(id, transactionData) { return this.creditTransactionRepository.update(id, transactionData); }
}

class DeleteCreditTransaction {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(id) { return this.creditTransactionRepository.delete(id); }
}

module.exports = { GetAllCreditTransactions, GetCreditTransactionsByCustomer, CreateCreditTransaction, UpdateCreditTransaction, DeleteCreditTransaction };
