const { db } = require('../config/firebaseAdmin');
const Sale = require('../domain/entities/Sale');
const ISaleRepository = require('../domain/repositories/ISaleRepository');

class FirestoreSaleRepository extends ISaleRepository {
    constructor() {
        super();
        this.collection = db.collection('sales');
    }

    async getAll() {
        const snapshot = await this.collection.orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const sale = new Sale({ id: doc.id, ...doc.data() });
            return sale.toJSON();
        });
    }

    async getById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const sale = new Sale({ id: doc.id, ...doc.data() });
        return sale.toJSON();
    }

    async getByCustomer(customerId) {
        const snapshot = await this.collection
            .where('customerId', '==', customerId)
            .orderBy('createdAt', 'desc')
            .get();
        return snapshot.docs.map(doc => {
            const sale = new Sale({ id: doc.id, ...doc.data() });
            return sale.toJSON();
        });
    }

    async create(saleData) {
        const now = new Date().toISOString();
        const dataToSave = {
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
            // Use the provided ID (useful for pre-confirmation display)
            docRef = this.collection.doc(saleData.id);
            await docRef.set(dataToSave);
        } else {
            // Auto-generate ID
            docRef = await this.collection.add(dataToSave);
        }

        const sale = new Sale({ id: docRef.id, ...dataToSave });
        return sale.toJSON();
    }

    async update(id, saleData) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        const updateData = { ...saleData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const sale = new Sale({ id: updatedDoc.id, ...updatedDoc.data() });
        return sale.toJSON();
    }

    async delete(id) {
        await this.collection.doc(id).delete();
        return true;
    }
}

module.exports = FirestoreSaleRepository;
