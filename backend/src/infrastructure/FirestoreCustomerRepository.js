const { db } = require('../config/firebaseAdmin');
const Customer = require('../domain/entities/Customer');
const ICustomerRepository = require('../domain/repositories/ICustomerRepository');

class FirestoreCustomerRepository extends ICustomerRepository {
    constructor() {
        super();
        this.collection = db.collection('customers');
    }

    async getAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection.where('ownerId', '==', ownerId).get();
        const customers = snapshot.docs.map(doc => {
            const customer = new Customer({ id: doc.id, ...doc.data() });
            return customer.toJSON();
        });
        // Sort in-memory to avoid requiring composite indexes in Firestore
        return customers.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async getById(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const customer = new Customer({ id: doc.id, ...data });
        return customer.toJSON();
    }

    async create(customerData) {
        if (!customerData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const dataToSave = {
            ownerId: customerData.ownerId,
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

    async update(id, customerData, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        
        const existingData = doc.data();
        if (existingData.ownerId !== ownerId) return null;

        const updateData = { ...customerData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const customer = new Customer({ id: updatedDoc.id, ...updatedDoc.data() });
        return customer.toJSON();
    }

    async delete(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        
        const existingData = doc.data();
        if (existingData.ownerId !== ownerId) return false;

        await docRef.delete();
        return true;
    }
}

module.exports = FirestoreCustomerRepository;
