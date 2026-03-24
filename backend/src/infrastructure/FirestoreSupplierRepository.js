const { db } = require('../config/firebaseAdmin');
const Supplier = require('../domain/entities/Supplier');
const ISupplierRepository = require('../domain/repositories/ISupplierRepository');

class FirestoreSupplierRepository extends ISupplierRepository {
    constructor() {
        super();
        this.collection = db.collection('suppliers');
    }

    async getAll() {
        const snapshot = await this.collection.orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const supplier = new Supplier({ id: doc.id, ...doc.data() });
            return supplier.toJSON();
        });
    }

    async getById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        const supplier = new Supplier({ id: doc.id, ...doc.data() });
        return supplier.toJSON();
    }

    async create(supplierData) {
        const now = new Date().toISOString();
        const dataToSave = {
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

    async update(id, supplierData) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        const updateData = { ...supplierData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const supplier = new Supplier({ id: updatedDoc.id, ...updatedDoc.data() });
        return supplier.toJSON();
    }

    async delete(id) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        await docRef.delete();
        return true;
    }
}

module.exports = FirestoreSupplierRepository;
