const { db } = require('../config/firebaseAdmin');
const Sale = require('../domain/entities/Sale');
const ISaleRepository = require('../domain/repositories/ISaleRepository');

class FirestoreSaleRepository extends ISaleRepository {
    constructor() {
        super();
        this.collection = db.collection('sales');
    }

    async getAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection.where('ownerId', '==', ownerId).get();
        const sales = snapshot.docs.map(doc => {
            const sale = new Sale({ id: doc.id, ...doc.data() });
            return sale.toJSON();
        });
        // Sort in-memory to avoid requiring composite indexes in Firestore
        return sales.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async getById(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const sale = new Sale({ id: doc.id, ...data });
        return sale.toJSON();
    }

    async getByCustomer(customerId, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .where('customerId', '==', customerId)
            .get();
        const sales = snapshot.docs.map(doc => {
            const sale = new Sale({ id: doc.id, ...doc.data() });
            return sale.toJSON();
        });
        // Sort in-memory to avoid requiring composite indexes in Firestore
        return sales.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async create(saleData) {
        if (!saleData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const dataToSave = {
            ownerId: saleData.ownerId,
            items: saleData.items || [],
            customerId: saleData.customerId || '',
            customerName: saleData.customerName || 'Walk-in Customer',
            subtotal: saleData.subtotal || 0,
            totalAmount: saleData.totalAmount || 0,
            paymentMethod: saleData.paymentMethod || 'cash',
            status: saleData.status || 'completed',
            createdAt: now,
            updatedAt: now,
        };

        let docRef;
        if (saleData.id) {
            docRef = this.collection.doc(saleData.id);
            await docRef.set(dataToSave);
        } else {
            docRef = await this.collection.add(dataToSave);
        }

        const sale = new Sale({ id: docRef.id, ...dataToSave });
        return sale.toJSON();
    }

    async update(id, saleData, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        
        const existingData = doc.data();
        if (existingData.ownerId !== ownerId) return null;

        const updateData = { ...saleData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;
        
        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const sale = new Sale({ id: updatedDoc.id, ...updatedDoc.data() });
        return sale.toJSON();
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

module.exports = FirestoreSaleRepository;
