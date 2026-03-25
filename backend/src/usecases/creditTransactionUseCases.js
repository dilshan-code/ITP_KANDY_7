class GetAllCreditTransactions {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(ownerId) { return this.creditTransactionRepository.getAll(ownerId); }
}

// Retrieves a list of all debt/payment logs for a specific customer.
class GetCreditTransactionsByCustomer {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(customerId, ownerId) { return this.creditTransactionRepository.getByCustomer(customerId, ownerId); }
}

// Records a new credit (loan) or payment for a customer and updates their total balance.
class CreateCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }
    async execute(transactionData, ownerId) { 
        if (!transactionData || !ownerId) throw new Error('Transaction data and Owner ID are required');

        // 1. Create the transaction
        const txn = await this.creditTransactionRepository.create({ ...transactionData, ownerId });

        // 2. Update customer balance and status
        if (transactionData.customerId) {
            const customer = await this.customerRepository.getById(transactionData.customerId, ownerId);
            if (customer) {
                let newOutstanding = customer.totalOutstanding || 0;
                if (transactionData.type === 'credit') {
                    newOutstanding += (transactionData.amount || 0);
                } else if (transactionData.type === 'payment') {
                    newOutstanding -= (transactionData.amount || 0);
                }

                // If balance is 0 or less, we consider the debt 'paid'; otherwise, it's still 'active'.
                const newStatus = newOutstanding <= 0 ? 'paid' : 'active';
                
                await this.customerRepository.update(customer.id, { 
                    totalOutstanding: Math.max(0, newOutstanding),
                    status: newStatus 
                }, ownerId);
            }
        }
        return txn;
    }
}

class UpdateCreditTransaction {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(id, transactionData, ownerId) { return this.creditTransactionRepository.update(id, transactionData, ownerId); }
}

class DeleteCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }
    async execute(id, ownerId) { 
        if (!id || !ownerId) throw new Error('Transaction ID and Owner ID are required');

        // 1. Get the transaction before deleting it
        const txnSnapshot = await this.creditTransactionRepository.getById(id, ownerId);
        if (!txnSnapshot) return false;

        // 2. Revert the customer balance
        if (txnSnapshot.customerId) {
            const customer = await this.customerRepository.getById(txnSnapshot.customerId, ownerId);
            if (customer) {
                let newOutstanding = customer.totalOutstanding || 0;
                // If it was a credit, subtracting it reduces debt.
                // If it was a payment, adding it back increases debt.
                if (txnSnapshot.type === 'credit') {
                    newOutstanding -= (txnSnapshot.amount || 0);
                } else if (txnSnapshot.type === 'payment') {
                    newOutstanding += (txnSnapshot.amount || 0);
                }
                
                await this.customerRepository.update(customer.id, { 
                    totalOutstanding: Math.max(0, newOutstanding),
                    status: newOutstanding <= 0 ? 'paid' : 'active'
                }, ownerId);
            }
        }

        // 3. Delete the transaction
        return this.creditTransactionRepository.delete(id, ownerId);
    }
}

module.exports = { GetAllCreditTransactions, GetCreditTransactionsByCustomer, CreateCreditTransaction, UpdateCreditTransaction, DeleteCreditTransaction };
