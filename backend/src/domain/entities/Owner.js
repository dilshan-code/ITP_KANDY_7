// The Owner entity represents the shop manager who has full access to the application.
class Owner {
    constructor({ 
        id, 
        name, 
        shopName, // The name of the business entity
        phone, 
        email, 
        password, // Encrypted password string
        createdAt, 
        updatedAt,
        role
    }) {
        this.id = id;
        this.name = name || '';
        this.shopName = shopName || '';
        this.phone = phone || '';
        this.email = email || '';
        this.password = password || '';
        this.createdAt = createdAt || new Date().toISOString();
        this.updatedAt = updatedAt || new Date().toISOString();
        this.role = role || 'owner';
    }

    toJSON() {
        return {
            id: this.id,
            name: this.name,
            shopName: this.shopName,
            phone: this.phone,
            email: this.email,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
            role: this.role
        };
    }
}

module.exports = Owner;
