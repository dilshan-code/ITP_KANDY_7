// The Supplier entity represents a business that provides products to the shop.
class Supplier {
    constructor({ 
        id, 
        name, 
        phone, 
        address, 
        email, 
        notes, 
        status, 
        totalPayable, // The total amount of money the shop owner currently owes this supplier
        createdAt, 
        updatedAt 
    }) {
        this.id = id;
        this.name = name || '';
        this.phone = phone || '';
        this.address = address || '';
        this.email = email || '';
        this.notes = notes || '';
        this.status = status || 'active';
        this.totalPayable = totalPayable || 0;
        this.createdAt = createdAt || new Date().toISOString();
        this.updatedAt = updatedAt || new Date().toISOString();
    }

    toJSON() {
        return {
            id: this.id,
            name: this.name,
            phone: this.phone,
            address: this.address,
            email: this.email,
            notes: this.notes,
            status: this.status,
            totalPayable: this.totalPayable,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
        };
    }
}

module.exports = Supplier;
