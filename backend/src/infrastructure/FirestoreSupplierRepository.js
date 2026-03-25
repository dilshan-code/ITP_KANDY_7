const { db } = require('../config/firebaseAdmin');
const Supplier = require('../domain/entities/Supplier');
const ISupplierRepository = require('../domain/repositories/ISupplierRepository');

class FirestoreSupplierRepository extends ISupplierRepository {
    constructor() {
        super();
        this.collection = db.collection('suppliers');
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
            const supplier = new Supplier({ id: doc.id, ...doc.data() });
            return supplier.toJSON();
        });
    }

    async getTotalPayable(ownerId) {
        const { AggregateField } = require('firebase-admin/firestore');
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .aggregate({
                total: AggregateField.sum('totalPayable')
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
        const supplier = new Supplier({ id: doc.id, ...data });
        return supplier.toJSON();
    }

    async create(supplierData, transaction = null) {
        if (!supplierData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const dataToSave = {
            ownerId: supplierData.ownerId,
            name: supplierData.name || '',
            phone: supplierData.phone || '',
            address: supplierData.address || '',
            email: supplierData.email || '',
            notes: supplierData.notes || '',
            status: 'active',
            totalPayable: 0,
            createdAt: now,
            updatedAt: now,
        };
        
        if (transaction) {
            const docRef = this.collection.doc();
            transaction.set(docRef, dataToSave);
            return new Supplier({ id: docRef.id, ...dataToSave }).toJSON();
        } else {
            const docRef = await this.collection.add(dataToSave);
            return new Supplier({ id: docRef.id, ...dataToSave }).toJSON();
        }
    }

    async update(id, supplierData, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        
        // In a transaction, we should have already fetched the doc in the read phase,
        // so we don't necessarily need to check exists here if we trust the use case.
        // But for safety, we can just perform the update.
        
        const updateData = { ...supplierData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        if (transaction) {
            transaction.update(docRef, updateData);
            return { id, ...updateData }; // Partial return is fine for use cases
        } else {
            // For non-transactional updates, we still need to verify ownership and existence
            const doc = await docRef.get();
            if (!doc.exists) return null;
            const existingData = doc.data();
            if (existingData.ownerId !== ownerId) return null;

            await docRef.update(updateData);
            const updatedDoc = await docRef.get();
            return new Supplier({ id: updatedDoc.id, ...updatedDoc.data() }).toJSON();
        }
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

module.exports = FirestoreSupplierRepository;
