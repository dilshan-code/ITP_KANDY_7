const { db } = require('../config/firebaseAdmin');
const Customer = require('../domain/entities/Customer');
const ICustomerRepository = require('../domain/repositories/ICustomerRepository');

class FirestoreCustomerRepository extends ICustomerRepository {
    constructor() {
        super();
        this.collection = db.collection('customers');
    }

    async getAll() {
        const snapshot = await this.collection.orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const customer = new Customer({ id: doc.id, ...doc.data() });
            return customer.toJSON();
        });
    }

    async getById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const customer = new Customer({ id: doc.id, ...doc.data() });
        return customer.toJSON();
    }

    async create(customerData) {
        const now = new Date().toISOString();
        const dataToSave = {
            name: customerData.name,
            phone: customerData.phone || '',
            imageUrl: customerData.imageUrl || '',
            totalOutstanding: 0,
            creditLimit: customerData.creditLimit || 5000,
            status: 'active',
            lastPurchase: '',
            createdAt: now,
            updatedAt: now,
        };
        const docRef = await this.collection.add(dataToSave);
        const customer = new Customer({ id: docRef.id, ...dataToSave });
        return customer.toJSON();
    }

    async update(id, customerData) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        const updateData = { ...customerData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const customer = new Customer({ id: updatedDoc.id, ...updatedDoc.data() });
        return customer.toJSON();
    }

    async delete(id) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        await docRef.delete();
        return true;
    }
}

module.exports = FirestoreCustomerRepository;
