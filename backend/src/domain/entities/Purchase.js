// The Purchase entity represents a transaction where the shop owner buys new stock from a supplier.
class Purchase {
    constructor({ 
        id, 
        supplierId, 
        supplierName, 
        invoiceNumber, 
        purchaseDate, 
        items, // List of products being purchased
        subtotal, 
        tax, 
        totalAmount, // Final cost to the shop
        amountPaid, // How much has been paid upfront
        remaining, // Amount still owed to the supplier
        status, // 'pending' or 'completed'
        notes, // Optional notes about the purchase
        createdAt, 
        updatedAt 
    }) {
        this.id = id;
        this.supplierId = supplierId || '';
        this.supplierName = supplierName || '';
        this.invoiceNumber = invoiceNumber || '';
        this.purchaseDate = purchaseDate;
        this.items = items || [];
        this.subtotal = subtotal || 0;
        this.tax = tax || 0;
        this.totalAmount = totalAmount || 0;
        this.amountPaid = amountPaid || 0;
        this.remaining = remaining || 0;
        this.status = status || 'pending';
        this.notes = notes || '';
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    toJSON() {
        return {
            id: this.id,
            supplierId: this.supplierId,
            supplierName: this.supplierName,
            invoiceNumber: this.invoiceNumber,
            purchaseDate: this.purchaseDate,
            items: this.items.map(item => ({
                ...item,
                name: item.productName || item.name,
                price: item.costPrice || item.price || 0
            })),
            subtotal: this.subtotal,
            tax: this.tax,
            totalAmount: this.totalAmount,
            amountPaid: this.amountPaid,
            remaining: this.remaining,
            status: this.status,
            notes: this.notes,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

module.exports = Purchase;
