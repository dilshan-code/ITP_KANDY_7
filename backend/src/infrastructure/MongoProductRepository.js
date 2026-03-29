const { v4: uuidv4 } = require('uuid');
const ProductModel = require('./models/Product');
const Product = require('../domain/entities/Product');
const IProductRepository = require('../domain/repositories/IProductRepository');

// This repository uses Mongoose to interact with the MongoDB 'products' collection.
class MongoProductRepository extends IProductRepository {
    constructor() {
        super();
        this.model = ProductModel;
    }

    // Retrieves all products for an owner, with optional pagination.
    async getAll(ownerId, limit = null, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId };
        
        // MongoDB uses the '_id' field for unique identification and efficient sorting.
        if (lastId) {
            query._id = { $gt: lastId };
        }

        let mongoQuery = this.model.find(query).sort({ name: 1 });

        if (limit) {
            mongoQuery = mongoQuery.limit(parseInt(limit));
        }

        const docs = await mongoQuery.exec();
        
        return docs.map(doc => {
            const product = new Product({ id: doc._id.toString(), ...doc.toJSON() });
            return product.toJSON();
        });
    }

    // Counts how many products are currently at or below their minimum stock level.
    async getLowStockCount(ownerId) {
        // We use $expr to perform server-side comparison of document fields.
        return this.model.countDocuments({
            ownerId,
            $expr: { $lte: ["$stockQuantity", "$minimumStockLevel"] }
        });
    }

    async getTotalStockQuantity(ownerId) {
        const result = await this.model.aggregate([
            { $match: { ownerId } },
            { $group: { _id: null, total: { $sum: "$stockQuantity" } } }
        ]);
        return result.length > 0 ? result[0].total : 0;
    }

    async getById(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        const doc = await this.model.findOne({ _id: id, ownerId }).session(session);
        if (!doc) return null;

        return new Product({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    // Creates a new product record in the MongoDB collection.
    async create(productData, session = null) {
        if (!productData.ownerId) throw new Error('Owner ID is required');

        const now = new Date().toISOString();
        const data = {
            // Generate a fresh UUID for the MongoDB document ID.
            _id: productData.id || productData._id || uuidv4(),
            ...productData,
            createdAt: now,
            updatedAt: now
        };
        delete data.id;

        // Using model.create with an array enables session-based transactions.
        const [doc] = await this.model.create([data], { session });
        return new Product({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async update(id, productData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const updateData = { 
            ...productData, 
            updatedAt: new Date().toISOString() 
        };
        delete updateData.id;
        delete updateData.ownerId;

        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $set: updateData },
            { new: true, session }
        );

        if (!doc) return null;
        return new Product({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async delete(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        return result.deletedCount > 0;
    }
}

module.exports = MongoProductRepository;
