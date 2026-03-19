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
        createdAt, 
        updatedAt 
    }) {
        this.id = id;
        this.supplierId = supplierId || '';
        this.supplierName = supplierName || '';
        this.invoiceNumber = invoiceNumber || '';
        this.purchaseDate = purchaseDate || new Date().toISOString();
        this.items = items || [];
        this.subtotal = subtotal || 0;
        this.tax = tax || 0;
        this.totalAmount = totalAmount || 0;
        this.amountPaid = amountPaid || 0;
        this.remaining = remaining || 0;
        this.status = status || 'pending';
        this.createdAt = createdAt || new Date().toISOString();
        this.updatedAt = updatedAt || new Date().toISOString();
    }

    toJSON() {
        return {
            id: this.id,
            supplierId: this.supplierId,
            supplierName: this.supplierName,
            invoiceNumber: this.invoiceNumber,
            purchaseDate: this.purchaseDate,
            items: this.items,
            subtotal: this.subtotal,
            tax: this.tax,
            totalAmount: this.totalAmount,
            amountPaid: this.amountPaid,
            remaining: this.remaining,
            status: this.status,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

module.exports = Purchase;
