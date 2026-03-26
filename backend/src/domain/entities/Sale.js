// The Sale entity represents a single transaction where a customer buys items.
class Sale {
    constructor({ 
        id, 
        items, // List of products sold
        customerId, 
        customerName, 
        subtotal, 
        totalAmount, // Final price including any adjustment
        paymentMethod, // Usually 'cash' or 'credit'
        status, 
        createdAt, 
        updatedAt 
    }) {
        this.id = id;
        this.items = items || [];
        this.customerId = customerId || '';
        this.customerName = customerName || 'Walk-in Customer';
        this.subtotal = subtotal || 0;
        this.totalAmount = totalAmount || 0;
        this.paymentMethod = paymentMethod || 'cash'; // 'cash' or 'credit'
        this.status = status || 'completed';
        this.createdAt = createdAt || new Date().toISOString();
        this.updatedAt = updatedAt || new Date().toISOString();
    }

    toJSON() {
        return {
            id: this.id,
            items: this.items.map(item => ({
                ...item,
                name: item.productName || item.name,
                price: item.unitPrice || item.price || 0
            })),
            customerId: this.customerId,
            customerName: this.customerName,
            subtotal: this.subtotal,
            totalAmount: this.totalAmount,
            paymentMethod: this.paymentMethod,
            status: this.status,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

module.exports = Sale;
