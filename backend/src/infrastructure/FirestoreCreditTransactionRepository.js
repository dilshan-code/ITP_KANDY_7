const { db } = require('../config/firebaseAdmin');
const CreditTransaction = require('../domain/entities/CreditTransaction');
const ICreditTransactionRepository = require('../domain/repositories/ICreditTransactionRepository');

class FirestoreCreditTransactionRepository extends ICreditTransactionRepository {
    constructor() {
        super();
        this.collection = db.collection('credit_transactions');
    }

    async getAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection.where('ownerId', '==', ownerId).get();
        const transactions = snapshot.docs.map(doc => {
            const txn = new CreditTransaction({ id: doc.id, ...doc.data() });
            return txn.toJSON();
        });
        // Sort in-memory to avoid requiring composite indexes in Firestore
        return transactions.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async getByCustomer(customerId, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .where('customerId', '==', customerId)
            .get();
        const transactions = snapshot.docs.map(doc => {
            const txn = new CreditTransaction({ id: doc.id, ...doc.data() });
            return txn.toJSON();
        });
        // Sort in-memory to avoid requiring composite indexes in Firestore
        return transactions.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async getById(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const txn = new CreditTransaction({ id: doc.id, ...data });
        return txn.toJSON();
    }

    async create(transactionData) {
        if (!transactionData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const dataToSave = {
            ownerId: transactionData.ownerId,
            customerId: transactionData.customerId,
            type: transactionData.type || 'credit',
            title: transactionData.title || '',
            amount: transactionData.amount || 0,
            date: transactionData.date || now,
            createdAt: now,
        };
        const docRef = await this.collection.add(dataToSave);
        const txn = new CreditTransaction({ id: docRef.id, ...dataToSave });
        return txn.toJSON();
    }

    async update(id, transactionData, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        
        const existingData = doc.data();
        if (existingData.ownerId !== ownerId) return null;

        const updateData = { ...transactionData };
        delete updateData.id;
        delete updateData.ownerId;

        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const txn = new CreditTransaction({ id: updatedDoc.id, ...updatedDoc.data() });
        return txn.toJSON();
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

module.exports = FirestoreCreditTransactionRepository;
