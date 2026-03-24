const { db } = require('../config/firebaseAdmin');
const Owner = require('../domain/entities/Owner');
const IOwnerRepository = require('../domain/repositories/IOwnerRepository');

class FirestoreOwnerRepository extends IOwnerRepository {
    constructor() {
        super();
        this.collection = db.collection('owners');
    }

    async create(ownerData) {
        const now = new Date().toISOString();
        const dataToSave = {
            name: ownerData.name,
            shopName: ownerData.shopName,
            phone: ownerData.phone,
            email: ownerData.email,
            password: ownerData.password, // Already hashed by use case
            createdAt: now,
            updatedAt: now,
        };
        const docRef = await this.collection.add(dataToSave);
        const owner = new Owner({ id: docRef.id, ...dataToSave });
        return owner.toJSON();
    }

    async findByEmail(email) {
        const snapshot = await this.collection.where('email', '==', email).get();
        if (snapshot.empty) return null;
        const doc = snapshot.docs[0];
        const data = doc.data();
        return { id: doc.id, ...data };
    }

    async getAll() {
        const snapshot = await this.collection.get();
        return snapshot.docs.map(doc => {
            const data = doc.data();
            return { id: doc.id, ...data };
        });
    }

    async findByPhone(phone) {
        const snapshot = await this.collection.where('phone', '==', phone).get();
        if (snapshot.empty) return null;
        const doc = snapshot.docs[0];
        const data = doc.data();
        return { id: doc.id, ...data };
    }

    async getById(id) {
        const owner = await this.getByIdWithPassword(id);
        return owner ? owner.toJSON() : null;
    }

    async getByIdWithPassword(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;
        return new Owner({ id: doc.id, ...doc.data() });
    }

    async update(id, ownerData) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        const updateData = { ...ownerData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        await docRef.update(updateData);
        const updatedDoc = await docRef.get();
        const owner = new Owner({ id: updatedDoc.id, ...updatedDoc.data() });
        return owner.toJSON();
    }

    async delete(id) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        await docRef.delete();
        return true;
    }
}

module.exports = FirestoreOwnerRepository;
