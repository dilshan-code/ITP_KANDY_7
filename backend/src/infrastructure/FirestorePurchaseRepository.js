const { db } = require('../config/firebaseAdmin');
const Purchase = require('../domain/entities/Purchase');
const IPurchaseRepository = require('../domain/repositories/IPurchaseRepository');

class FirestorePurchaseRepository extends IPurchaseRepository {
    constructor() {
        super();
        this.collection = db.collection('purchases');
    }

    async getAll() {
        const snapshot = await this.collection.orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const purchase = new Purchase({ id: doc.id, ...doc.data() });
            return purchase.toJSON();
        });
    }

    async getById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const purchase = new Purchase({ id: doc.id, ...doc.data() });
        return purchase.toJSON();
    }

    async create(purchaseData) {
        const now = new Date().toISOString();
        const remaining = (purchaseData.totalAmount || 0) - (purchaseData.amountPaid || 0);
        let status = 'pending';
        if (remaining <= 0) status = 'paid';
        else if (purchaseData.amountPaid > 0) status = 'partial';

        const dataToSave = {
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

    async getBySupplier(supplierId) {
        const snapshot = await this.collection.where('supplierId', '==', supplierId).orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const purchase = new Purchase({ id: doc.id, ...doc.data() });
            return purchase.toJSON();
        });
    }

    async update(id, purchaseData) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;

        const updateData = {
            ...purchaseData,
            updatedAt: new Date().toISOString(),
        };
        delete updateData.id;

        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        return new Purchase({ id: updatedDoc.id, ...updatedDoc.data() }).toJSON();
    }

    async delete(id) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        await docRef.delete();
        return true;
    }
}

module.exports = FirestorePurchaseRepository;
