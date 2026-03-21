// Core Sale domain entity — independent of any database or framework
class Sale {
    constructor({
        id,
        invoiceId,
        customerName,
        isCredit,
        status,
        subtotal,
        tax,
        totalAmount,
        items,
        date,
        createdAt,
        updatedAt,
    }) {
        this.id = id;
        this.invoiceId = invoiceId || '';
        this.customerName = customerName || 'Walk-in Customer';
        this.isCredit = isCredit || false;
        this.status = status || 'Completed'; // 'Completed' | 'Credit'
        this.subtotal = subtotal || 0;
        this.tax = tax || 0;
        this.totalAmount = totalAmount || 0;
        this.items = items || []; // Array of sale items
        this.date = date || new Date().toISOString();
        this.createdAt = createdAt || new Date().toISOString();
        this.updatedAt = updatedAt || new Date().toISOString();
    }

    // Calculated getter — how many individual items in this sale
    get itemCount() {
        return this.items.reduce((sum, item) => sum + (item.quantity || 0), 0);
    }

    toJSON() {
        return {
            id: this.id,
            invoiceId: this.invoiceId,
            customerName: this.customerName,
            isCredit: this.isCredit,
            status: this.status,
            subtotal: this.subtotal,
            tax: this.tax,
            totalAmount: this.totalAmount,
            items: this.items,
            itemCount: this.itemCount,
            date: this.date,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

module.exports = Sale;
