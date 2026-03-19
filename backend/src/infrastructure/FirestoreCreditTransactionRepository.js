const { db } = require('../config/firebaseAdmin');
const CreditTransaction = require('../domain/entities/CreditTransaction');
const ICreditTransactionRepository = require('../domain/repositories/ICreditTransactionRepository');

class FirestoreCreditTransactionRepository extends ICreditTransactionRepository {
    constructor() {
        super();
        this.collection = db.collection('credit_transactions');
    }

    async getAll() {
        const snapshot = await this.collection.orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const txn = new CreditTransaction({ id: doc.id, ...doc.data() });
            return txn.toJSON();
        });
    }

    async getByCustomer(customerId) {
        const snapshot = await this.collection.where('customerId', '==', customerId).orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const txn = new CreditTransaction({ id: doc.id, ...doc.data() });
            return txn.toJSON();
        });
    }

    async create(transactionData) {
        const now = new Date().toISOString();
        const dataToSave = {
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

    async update(id, transactionData) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        const updateData = { ...transactionData };
        delete updateData.id;
        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const txn = new CreditTransaction({ id: updatedDoc.id, ...updatedDoc.data() });
        return txn.toJSON();
    }

    async delete(id) {
        await this.collection.doc(id).delete();
        return true;
    }
}

module.exports = FirestoreCreditTransactionRepository;
