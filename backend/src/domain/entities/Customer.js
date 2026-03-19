// The Customer entity represents a person or business that buys from the shop, often on credit.
class Customer {
    constructor({ 
        id, 
        name, 
        phone, 
        imageUrl, 
        totalOutstanding, // The amount of money this customer currently owes the shop
        creditLimit, // The maximum amount of debt this customer is allowed to have
        status, 
        lastPurchase, 
        createdAt, 
        updatedAt 
    }) {
        this.id = id;
        this.name = name || '';
        this.phone = phone || '';
        this.imageUrl = imageUrl || '';
        this.totalOutstanding = totalOutstanding || 0;
        this.creditLimit = creditLimit || 0;
        this.status = status || 'active';
        this.lastPurchase = lastPurchase || '';
        this.createdAt = createdAt || new Date().toISOString();
        this.updatedAt = updatedAt || new Date().toISOString();
    }

    toJSON() {
        return {
            id: this.id,
            name: this.name,
            phone: this.phone,
            imageUrl: this.imageUrl,
            totalOutstanding: this.totalOutstanding,
            creditLimit: this.creditLimit,
            status: this.status,
            lastPurchase: this.lastPurchase,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

module.exports = Customer;
