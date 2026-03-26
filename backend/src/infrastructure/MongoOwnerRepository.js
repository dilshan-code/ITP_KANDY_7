const { v4: uuidv4 } = require('uuid');
const OwnerModel = require('./models/Owner');
const Owner = require('../domain/entities/Owner');
const IOwnerRepository = require('../domain/repositories/IOwnerRepository');

class MongoOwnerRepository extends IOwnerRepository {
    constructor() {
        super();
        this.model = OwnerModel;
    }

    async create(ownerData) {
        const now = new Date().toISOString();
        const data = {
            ...ownerData,
            _id: ownerData.id || ownerData._id || uuidv4(),
            createdAt: now,
            updatedAt: now
        };
        delete data.id;
        const [doc] = await this.model.create([data]);
        const owner = new Owner(doc.toJSON());
        return owner.toJSON();
    }

    async findByEmail(email) {
        const doc = await this.model.findOne({ email });
        if (!doc) return null;
        return doc.toJSON();
    }

    async findByPhone(phone) {
        const doc = await this.model.findOne({ phone });
        if (!doc) return null;
        return doc.toJSON();
    }

    async getById(id) {
        const doc = await this.model.findById(id);
        if (!doc) return null;
        const owner = new Owner(doc.toJSON());
        return owner.toJSON();
    }

    async getByIdWithPassword(id) {
        const doc = await this.model.findById(id);
        if (!doc) return null;
        return new Owner(doc.toJSON());
    }

    async getAll() {
        const docs = await this.model.find({});
        return docs.map(doc => new Owner({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
    }

    async update(id, ownerData) {
        const updateData = {
            ...ownerData,
            updatedAt: new Date().toISOString()
        };
        delete updateData.id;

        const doc = await this.model.findByIdAndUpdate(
            id,
            { $set: updateData },
            { new: true }
        );

        if (!doc) return null;
        const owner = new Owner(doc.toJSON());
        return owner.toJSON();
    }

    async delete(id) {
        const result = await this.model.deleteOne({ _id: id });
        return result.deletedCount > 0;
    }
}

module.exports = MongoOwnerRepository;
