const { v4: uuidv4 } = require('uuid');
const SupplierModel = require('./models/Supplier');
const Supplier = require('../domain/entities/Supplier');
const ISupplierRepository = require('../domain/repositories/ISupplierRepository');

class MongoSupplierRepository extends ISupplierRepository {
    constructor() {
        super();
        this.model = SupplierModel;
    }

    async getAll(ownerId, limit = null, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId };
        if (lastId) {
            query._id = { $lt: lastId };
        }

        let mongoQuery = this.model.find(query).sort({ createdAt: -1 });
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        return docs.map(doc => new Supplier({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
    }

    async getTotalPayable(ownerId) {
        const result = await this.model.aggregate([
            { $match: { ownerId } },
            { $group: { _id: null, total: { $sum: "$totalPayable" } } }
        ]);
        return result.length > 0 ? result[0].total : 0;
    }

    async getById(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.model.findOne({ _id: id, ownerId }).session(session);
        if (!doc) return null;
        return new Supplier({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async create(supplierData, session = null) {
        if (!supplierData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const data = {
            _id: supplierData.id || supplierData._id || uuidv4(),
            ...supplierData,
            status: 'active',
            totalPayable: 0,
            createdAt: now,
            updatedAt: now
        };
        delete data.id;
        const [doc] = await this.model.create([data], { session });
        return new Supplier({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async update(id, supplierData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const updateData = { ...supplierData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $set: updateData },
            { new: true, session }
        );

        if (!doc) return null;
        return new Supplier({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async delete(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        return result.deletedCount > 0;
    }
}

module.exports = MongoSupplierRepository;
