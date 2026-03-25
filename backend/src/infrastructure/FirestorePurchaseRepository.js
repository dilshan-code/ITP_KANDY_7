const { db } = require('../config/firebaseAdmin');
const Purchase = require('../domain/entities/Purchase');
const IPurchaseRepository = require('../domain/repositories/IPurchaseRepository');

class FirestorePurchaseRepository extends IPurchaseRepository {
    constructor() {
        super();
        this.collection = db.collection('purchases');
    }

    async getTotalPurchases(ownerId) {
        const { AggregateField } = require('firebase-admin/firestore');
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .aggregate({
                total: AggregateField.sum('totalAmount')
            })
            .get();
        return snapshot.data().total;
    }

    async getAllByDateRange(ownerId, startDate, endDate) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .where('createdAt', '>=', startDate)
            .where('createdAt', '<=', endDate)
            .orderBy('createdAt', 'desc')
            .get();
            
        return snapshot.docs.map(doc => {
            const purchase = new Purchase({ id: doc.id, ...doc.data() });
            return purchase.toJSON();
        });
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
            const purchase = new Purchase({ id: doc.id, ...doc.data() });
            return purchase.toJSON();
        });
    }

    async getById(id, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = transaction ? await transaction.get(docRef) : await docRef.get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const purchase = new Purchase({ id: doc.id, ...data });
        return purchase.toJSON();
    }

    async create(purchaseData, transaction = null) {
        if (!purchaseData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const remaining = (purchaseData.totalAmount || 0) - (purchaseData.amountPaid || 0);
        let status = 'pending';
        if (remaining <= 0) status = 'paid';
        else if (purchaseData.amountPaid > 0) status = 'partial';

        const dataToSave = {
            ownerId: purchaseData.ownerId,
            supplierId: purchaseData.supplierId,
            supplierName: purchaseData.supplierName || '',
            invoiceNumber: purchaseData.invoiceNumber || '',
            purchaseDate: purchaseData.purchaseDate || now,
            items: purchaseData.items || [],
            subtotal: purchaseData.subtotal || 0,
            tax: purchaseData.tax || 0,
            totalAmount: purchaseData.totalAmount || 0,
            amountPaid: purchaseData.amountPaid || 0,
            remaining: remaining,
            status: status,
            notes: purchaseData.notes || '',
            createdAt: now,
            updatedAt: now,
        };

        if (transaction) {
            const docRef = this.collection.doc();
            transaction.set(docRef, dataToSave);
            return new Purchase({ id: docRef.id, ...dataToSave }).toJSON();
        } else {
            const docRef = await this.collection.add(dataToSave);
            return new Purchase({ id: docRef.id, ...dataToSave }).toJSON();
        }
    }

    async getBySupplier(supplierId, ownerId, limit, lastId) {
        if (!ownerId) throw new Error('Owner ID is required');

        let query = this.collection
            .where('ownerId', '==', ownerId)
            .where('supplierId', '==', supplierId)
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
            const purchase = new Purchase({ id: doc.id, ...doc.data() });
            return purchase.toJSON();
        });
    }

    async update(id, purchaseData, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        
        const existingData = doc.data();
        if (existingData.ownerId !== ownerId) return null;

        const updateData = {
            ...purchaseData,
            updatedAt: new Date().toISOString(),
        };
        delete updateData.id;
        delete updateData.ownerId;

        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        return new Purchase({ id: updatedDoc.id, ...updatedDoc.data() }).toJSON();
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
            if (doc.data().ownerId !== ownerId) return false;
            await docRef.delete();
            return true;
        }
    }
}

module.exports = FirestorePurchaseRepository;
