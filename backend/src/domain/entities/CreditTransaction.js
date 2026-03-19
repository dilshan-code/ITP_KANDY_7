// The CreditTransaction entity represents a single log entry for a customer's credit or payment activity.
class CreditTransaction {
    constructor({ 
        id, 
        customerId, 
        type, // 'credit' (customer owes money) or 'payment' (customer pays back)
        title, 
        amount, 
        date, 
        createdAt 
    }) {
        this.id = id;
        this.customerId = customerId || '';
        this.type = type || 'credit'; // 'credit' or 'payment'
        this.title = title || '';
        this.amount = amount || 0;
        this.date = date || new Date().toISOString();
        this.createdAt = createdAt || new Date().toISOString();
    }

    toJSON() {
        return {
            id: this.id,
            customerId: this.customerId,
            type: this.type,
            title: this.title,
            amount: this.amount,
            date: this.date,
            createdAt: this.createdAt,
        };
    }
}

module.exports = CreditTransaction;
