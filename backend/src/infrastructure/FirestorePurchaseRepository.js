const { db } = require('../config/firebaseAdmin');
const Purchase = require('../domain/entities/Purchase');
const IPurchaseRepository = require('../domain/repositories/IPurchaseRepository');

class FirestorePurchaseRepository extends IPurchaseRepository {
    constructor() {
        super();
        this.collection = db.collection('purchases');
    }

    async getAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection.where('ownerId', '==', ownerId).get();
        const purchases = snapshot.docs.map(doc => {
            const purchase = new Purchase({ id: doc.id, ...doc.data() });
            return purchase.toJSON();
        });
        // Sort in-memory to avoid requiring composite indexes in Firestore
        return purchases.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async getById(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const purchase = new Purchase({ id: doc.id, ...data });
        return purchase.toJSON();
    }

    async create(purchaseData) {
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
        const docRef = await this.collection.add(dataToSave);
        const purchase = new Purchase({ id: docRef.id, ...dataToSave });
        return purchase.toJSON();
    }

    async getBySupplier(supplierId, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .where('supplierId', '==', supplierId)
            .get();
        const purchases = snapshot.docs.map(doc => {
            const purchase = new Purchase({ id: doc.id, ...doc.data() });
            return purchase.toJSON();
        });
        // Sort in-memory to avoid requiring composite indexes in Firestore
        return purchases.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
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

module.exports = FirestorePurchaseRepository;
