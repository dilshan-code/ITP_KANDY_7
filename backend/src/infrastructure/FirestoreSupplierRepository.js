const { db } = require('../config/firebaseAdmin');
const Supplier = require('../domain/entities/Supplier');
const ISupplierRepository = require('../domain/repositories/ISupplierRepository');

class FirestoreSupplierRepository extends ISupplierRepository {
    constructor() {
        super();
        this.collection = db.collection('suppliers');
    }

    async getAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection.where('ownerId', '==', ownerId).orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const supplier = new Supplier({ id: doc.id, ...doc.data() });
            return supplier.toJSON();
        });
    }

    async getById(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const supplier = new Supplier({ id: doc.id, ...data });
        return supplier.toJSON();
    }

    async create(supplierData) {
        if (!supplierData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const dataToSave = {
            ownerId: supplierData.ownerId,
            name: supplierData.name,
            phone: supplierData.phone,
            address: supplierData.address || '',
            email: supplierData.email || '',
            notes: supplierData.notes || '',
            status: 'active',
            totalPayable: 0,
            createdAt: now,
            updatedAt: now,
        };
        const docRef = await this.collection.add(dataToSave);
        const supplier = new Supplier({ id: docRef.id, ...dataToSave });
        return supplier.toJSON();
    }

    async update(id, supplierData, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        
        const existingData = doc.data();
        if (existingData.ownerId !== ownerId) return null;

        const updateData = { ...supplierData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const supplier = new Supplier({ id: updatedDoc.id, ...updatedDoc.data() });
        return supplier.toJSON();
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
