const { v4: uuidv4 } = require('uuid');
const CreditTransactionModel = require('./models/CreditTransaction');
const CreditTransaction = require('../domain/entities/CreditTransaction');
const ICreditTransactionRepository = require('../domain/repositories/ICreditTransactionRepository');

class MongoCreditTransactionRepository extends ICreditTransactionRepository {
    constructor() {
        super();
        this.model = CreditTransactionModel;
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
        return docs.map(doc => new CreditTransaction({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
    }

    async getByCustomer(customerId, ownerId, limit = null, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId, customerId };
        if (lastId) query._id = { $lt: lastId };

        let mongoQuery = this.model.find(query).sort({ createdAt: -1 });
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        return docs.map(doc => new CreditTransaction({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
    }

    async getById(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.model.findOne({ _id: id, ownerId }).session(session);
        if (!doc) return null;
        return new CreditTransaction({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async create(transactionData, session = null) {
        if (!transactionData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const data = {
            _id: transactionData.id || transactionData._id || uuidv4(),
            ...transactionData,
            createdAt: now,
            updatedAt: now
        };
        delete data.id;

        const [doc] = await this.model.create([data], { session });
        return new CreditTransaction({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async update(id, transactionData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const updateData = { ...transactionData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $set: updateData },
            { new: true, session }
        );

        if (!doc) return null;
        return new CreditTransaction({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async delete(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        return result.deletedCount > 0;
    }

    async deleteByTitle(ownerId, customerId, titlePattern, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const query = {
            ownerId,
            customerId,
            title: { $regex: titlePattern, $options: 'i' }
        };
        const result = await this.model.deleteOne(query).session(session);
        return result.deletedCount > 0;
    }
}

module.exports = MongoCreditTransactionRepository;
