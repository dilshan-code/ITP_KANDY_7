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
        updatedAt 
    }) {
        this.id = id;
        this.name = name || '';
        this.shopName = shopName || '';
        this.phone = phone || '';
        this.email = email || '';
        this.password = password || '';
        this.createdAt = createdAt || new Date().toISOString();
        this.updatedAt = updatedAt || new Date().toISOString();
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
        };
    }
}

module.exports = Owner;
