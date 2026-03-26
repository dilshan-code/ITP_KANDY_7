const mongoose = require('mongoose');

class GetAllCreditTransactions {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(ownerId, limit = null, lastId = null) { 
        return this.creditTransactionRepository.getAll(ownerId, limit, lastId); 
    }
}

class GetCreditTransactionsByCustomer {
    constructor(creditTransactionRepository) { this.creditTransactionRepository = creditTransactionRepository; }
    async execute(customerId, ownerId, limit = null, lastId = null) { 
        return this.creditTransactionRepository.getByCustomer(customerId, ownerId, limit, lastId); 
    }
}

class CreateCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }
    async execute(transactionData, ownerId) { 
        if (!transactionData || !ownerId) throw new Error('Transaction data and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            let customer = null;
            if (transactionData.customerId) {
                customer = await this.customerRepository.getById(transactionData.customerId, ownerId, session);
            }

            const txn = await this.creditTransactionRepository.create({ ...transactionData, ownerId }, session);

            if (customer) {
                let newOutstanding = customer.totalOutstanding || 0;
                const amount = parseFloat(transactionData.amount) || 0;
                if (transactionData.type === 'credit') {
                    newOutstanding += amount;
                } else if (transactionData.type === 'payment') {
                    newOutstanding -= amount;
                }
                const newStatus = newOutstanding <= 0 ? 'paid' : 'active';
                await this.customerRepository.update(customer.id, { 
                    totalOutstanding: Math.max(0, newOutstanding),
                    status: newStatus 
                }, ownerId, session);
            }

            await session.commitTransaction();
            return txn;
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    }
}

class UpdateCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }
    async execute(id, transactionData, ownerId) { 
        if (!id || !ownerId) throw new Error('Transaction ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            const oldTxn = await this.creditTransactionRepository.getById(id, ownerId, session);
            if (!oldTxn) throw new Error('Transaction not found');

            // 1. REVERT OLD BALANCE
            if (oldTxn.customerId) {
                const customer = await this.customerRepository.getById(oldTxn.customerId, ownerId, session);
                if (customer) {
                    let revertedOutstanding = customer.totalOutstanding || 0;
                    const amount = parseFloat(oldTxn.amount) || 0;
                    if (oldTxn.type === 'credit') {
                        revertedOutstanding -= amount;
                    } else if (oldTxn.type === 'payment') {
                        revertedOutstanding += amount;
                    }
                    await this.customerRepository.update(customer.id, { 
                        totalOutstanding: Math.max(0, revertedOutstanding)
                    }, ownerId, session);
                }
            }

            // 2. APPLY NEW BALANCE
            if (transactionData.customerId || oldTxn.customerId) {
                const customerId = transactionData.customerId || oldTxn.customerId;
                const customer = await this.customerRepository.getById(customerId, ownerId, session);
                if (customer) {
                    let newOutstanding = customer.totalOutstanding || 0;
                    const amount = parseFloat(transactionData.amount || oldTxn.amount) || 0;
                    const type = transactionData.type || oldTxn.type;
                    
                    if (type === 'credit') {
                        newOutstanding += amount;
                    } else if (type === 'payment') {
                        newOutstanding -= amount;
                    }
                    
                    const newStatus = newOutstanding <= 0 ? 'paid' : 'active';
                    await this.customerRepository.update(customer.id, { 
                        totalOutstanding: Math.max(0, newOutstanding),
                        status: newStatus 
                    }, ownerId, session);
                }
            }

            const updatedTxn = await this.creditTransactionRepository.update(id, transactionData, ownerId, session);
            await session.commitTransaction();
            return updatedTxn;
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    }
}

class DeleteCreditTransaction {
    constructor(creditTransactionRepository, customerRepository) { 
        this.creditTransactionRepository = creditTransactionRepository; 
        this.customerRepository = customerRepository;
    }
    async execute(id, ownerId) { 
        if (!id || !ownerId) throw new Error('Transaction ID and Owner ID are required');

        const session = await mongoose.startSession();
        try {
            session.startTransaction();
            
            const txn = await this.creditTransactionRepository.getById(id, ownerId, session);
            if (!txn) return false;

            if (txn.customerId) {
                const customer = await this.customerRepository.getById(txn.customerId, ownerId, session);
                if (customer) {
                    let newOutstanding = customer.totalOutstanding || 0;
                    const amount = parseFloat(txn.amount) || 0;
                    if (txn.type === 'credit') {
                        newOutstanding -= amount;
                    } else if (txn.type === 'payment') {
                        newOutstanding += amount;
                    }
                    await this.customerRepository.update(customer.id, { 
                        totalOutstanding: Math.max(0, newOutstanding),
                        status: newOutstanding <= 0 ? 'paid' : 'active'
                    }, ownerId, session);
                }
            }

            await this.creditTransactionRepository.delete(id, ownerId, session);
            await session.commitTransaction();
            return true;
        } catch (error) {
            await session.abortTransaction();
            throw error;
        } finally {
            session.endSession();
        }
    }
}

module.exports = { GetAllCreditTransactions, GetCreditTransactionsByCustomer, CreateCreditTransaction, UpdateCreditTransaction, DeleteCreditTransaction };
