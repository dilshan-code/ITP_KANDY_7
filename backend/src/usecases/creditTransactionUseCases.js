const { db } = require('../config/firebaseAdmin');

class GetAllCreditTransactions {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(ownerId, limit = null, lastId = null) { 
        return this.creditTransactionRepository.getAll(ownerId, limit, lastId); 
    }
}

// Retrieves a list of all debt/payment logs for a specific customer.
class GetCreditTransactionsByCustomer {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(customerId, ownerId, limit = null, lastId = null) { 
        return this.creditTransactionRepository.getByCustomer(customerId, ownerId, limit, lastId); 
    }
}

// Records a new credit (loan) or payment for a customer and updates their total balance.
class CreateCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }
    async execute(transactionData, ownerId) { 
        if (!transactionData || !ownerId) throw new Error('Transaction data and Owner ID are required');

        return await db.runTransaction(async (transaction) => {
            // --- READ PHASE ---
            let customer = null;
            if (transactionData.customerId) {
                customer = await this.customerRepository.getById(transactionData.customerId, ownerId, transaction);
            }

            // --- WRITE PHASE ---

            // 1. Create the transaction record
            const txn = await this.creditTransactionRepository.create({ ...transactionData, ownerId }, transaction);

            // 2. Update customer balance and status
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
                }, ownerId, transaction);
            }
            return txn;
        });
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

        return await db.runTransaction(async (transaction) => {
            // 1. Get the transaction before deleting it
            const txnSnapshot = await this.creditTransactionRepository.getById(id, ownerId, transaction);
            if (!txnSnapshot) return false;

            // 2. Revert the customer balance
            if (txnSnapshot.customerId) {
                const customer = await this.customerRepository.getById(txnSnapshot.customerId, ownerId, transaction);
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
                    }, ownerId, transaction);
                }
            }

            // 3. Delete the transaction record
            transaction.delete(db.collection('credit-transactions').doc(id));
            return true;
        });
    }
}

module.exports = { GetAllCreditTransactions, GetCreditTransactionsByCustomer, CreateCreditTransaction, UpdateCreditTransaction, DeleteCreditTransaction };
