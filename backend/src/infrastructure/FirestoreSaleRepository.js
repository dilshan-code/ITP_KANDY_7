const { db } = require('../config/firebaseAdmin');
const Sale = require('../domain/entities/Sale');
const ISaleRepository = require('../domain/repositories/ISaleRepository');

class FirestoreSaleRepository extends ISaleRepository {
    constructor() {
        super();
        this.collection = db.collection('sales');
    }

    async getTodayTotal(ownerId) {
        const { AggregateField } = require('firebase-admin/firestore');
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .where('createdAt', '>=', today.toISOString())
            .aggregate({
                total: AggregateField.sum('totalAmount')
            })
            .get();
        return snapshot.data().total;
    }

    async getTotalRevenue(ownerId) {
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
            const sale = new Sale({ id: doc.id, ...doc.data() });
            return sale.toJSON();
        });
    }

    async getAll(ownerId, limit = null, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        // Start building the query with mandatory ownerId filter and sorting
        let query = this.collection.where('ownerId', '==', ownerId).orderBy('createdAt', 'desc');

        // Apply pagination if a lastId is provided
        if (lastId) {
            const lastDoc = await this.collection.doc(lastId).get();
            if (lastDoc.exists) {
                query = query.startAfter(lastDoc);
            }
        }

        // Apply the limit if provided
        if (limit) {
            query = query.limit(parseInt(limit));
        }

        const snapshot = await query.get();
        return snapshot.docs.map(doc => {
            const sale = new Sale({ id: doc.id, ...doc.data() });
            return sale.toJSON();
        });
    }

    async getById(id, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = transaction ? await transaction.get(docRef) : await docRef.get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const sale = new Sale({ id: doc.id, ...data });
        return sale.toJSON();
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
            const sale = new Sale({ id: doc.id, ...doc.data() });
            return sale.toJSON();
        });
    }

    async create(saleData, transaction = null) {
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
            if (transaction) {
                transaction.set(docRef, dataToSave);
            } else {
                await docRef.set(dataToSave);
            }
        } else {
            if (transaction) {
                docRef = this.collection.doc(); // Generate ID
                transaction.set(docRef, dataToSave);
            } else {
                docRef = await this.collection.add(dataToSave);
            }
        }

        const sale = new Sale({ id: docRef.id, ...dataToSave });
        return sale.toJSON();
    }

    async update(id, saleData, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        
        const updateData = { ...saleData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        if (transaction) {
            transaction.update(docRef, updateData);
            return { id, ...updateData };
        } else {
            const doc = await docRef.get();
            if (!doc.exists) return null;
            if (doc.data().ownerId !== ownerId) return null;

            await docRef.update(updateData);
            const updatedDoc = await docRef.get();
            const sale = new Sale({ id: updatedDoc.id, ...updatedDoc.data() });
            return sale.toJSON();
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

module.exports = FirestoreSaleRepository;
