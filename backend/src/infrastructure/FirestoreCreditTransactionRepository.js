const { db } = require('../config/firebaseAdmin');
const CreditTransaction = require('../domain/entities/CreditTransaction');
const ICreditTransactionRepository = require('../domain/repositories/ICreditTransactionRepository');

class FirestoreCreditTransactionRepository extends ICreditTransactionRepository {
    constructor() {
        super();
        this.collection = db.collection('credit-transactions');
    }

    async getAll(ownerId, limit = null, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        let query = this.collection.where('ownerId', '==', ownerId).orderBy('createdAt', 'desc');

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
            const txn = new CreditTransaction({ id: doc.id, ...doc.data() });
            return txn.toJSON();
        });
    }

    async getByCustomer(customerId, ownerId, limit = null, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        let query = this.collection
            .where('ownerId', '==', ownerId)
            .where('customerId', '==', customerId)
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
            const txn = new CreditTransaction({ id: doc.id, ...doc.data() });
            return txn.toJSON();
        });
    }

    async getById(id, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = transaction ? await transaction.get(docRef) : await docRef.get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const txn = new CreditTransaction({ id: doc.id, ...data });
        return txn.toJSON();
    }

    async create(transactionData, transaction = null) {
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
        
        let docRef;
        if (transaction) {
            docRef = this.collection.doc();
            transaction.set(docRef, dataToSave);
        } else {
            docRef = await this.collection.add(dataToSave);
        }
        
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
