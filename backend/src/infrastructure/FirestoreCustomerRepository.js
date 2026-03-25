const { db } = require('../config/firebaseAdmin');
const Customer = require('../domain/entities/Customer');
const ICustomerRepository = require('../domain/repositories/ICustomerRepository');

class FirestoreCustomerRepository extends ICustomerRepository {
    constructor() {
        super();
        this.collection = db.collection('customers');
    }

    async getAll(ownerId, limit, lastId) {
        if (!ownerId) throw new Error('Owner ID is required');

        let query = this.collection
            .where('ownerId', '==', ownerId)
            .orderBy('createdAt', 'desc');

        if (lastId) {
            const lastDoc = await this.collection.doc(lastId).get();
            if (lastDoc.exists) {
                query = query.startAfter(lastDoc);
            }
        }

        if (limit) {
            query = query.limit(parseInt(limit));
        }

        const snapshot = await query.get();
        return snapshot.docs.map(doc => {
            const customer = new Customer({ id: doc.id, ...doc.data() });
            return customer.toJSON();
        });
    }

    async getTotalOutstanding(ownerId) {
        const { AggregateField } = require('firebase-admin/firestore');
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .aggregate({
                total: AggregateField.sum('totalOutstanding')
            })
            .get();
        return snapshot.data().total;
    }

    async getById(id, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = transaction ? await transaction.get(docRef) : await docRef.get();
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

    async update(id, customerData, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);

        if (!transaction) {
          const doc = await docRef.get();
          if (!doc.exists) return null;
          if (doc.data().ownerId !== ownerId) return null;
        }

        const updateData = { ...customerData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        if (transaction) {
            transaction.update(docRef, updateData);
            return { id, ...updateData }; // Return what we updated
        } else {
            await docRef.update(updateData);
            const updatedDoc = await docRef.get();
            const customer = new Customer({ id: updatedDoc.id, ...updatedDoc.data() });
            return customer.toJSON();
        }
    }

    async delete(id, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);

        if (transaction) {
            transaction.delete(docRef);
            return true;
        } else {
            const doc = await docRef.get();
            if (!doc.exists) return false;
            
            const existingData = doc.data();
            if (existingData.ownerId !== ownerId) return false;

            await docRef.delete();
            return true;
        }
    }
}

module.exports = FirestoreCustomerRepository;
