//Refactor MongoSalesRepository to streamline product object creation with consistent ID handling
const { v4: uuidv4 } = require('uuid');
const SaleModel = require('./models/Sale');
const Sale = require('../domain/entities/Sale');
const ISaleRepository = require('../domain/repositories/ISaleRepository');

class MongoSaleRepository extends ISaleRepository {
    constructor() {
        super();
        this.model = SaleModel;
    }

    // Calculates the total sales volume specifically for the current calendar day.
    async getTodayTotal(ownerId, timezoneOffset = 0) {
        // Find the start of the current day in the user's local timezone.
        // We adjust the current UTC time by the offset, reset to midnight, and adjust back to get the UTC starting point.
        const today = new Date();
        today.setUTCMinutes(today.getUTCMinutes() + timezoneOffset);
        today.setUTCHours(0, 0, 0, 0);
        today.setUTCMinutes(today.getUTCMinutes() - timezoneOffset);

        // Uses a MongoDB aggregation pipeline to filter sales by date and sum their totals.
        const result = await this.model.aggregate([
            { 
                $match: { 
                    ownerId, 
                    createdAt: { $gte: today.toISOString() },
                    status: 'completed'
                } 
            },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);

        return result.length > 0 ? result[0].total : 0;
    }

    async getTotalRevenue(ownerId) {
        const result = await this.model.aggregate([
            { $match: { ownerId } },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);

        return result.length > 0 ? result[0].total : 0;
    }

    async getTotalRevenueByDateRange(ownerId, startDate, endDate) {
        const result = await this.model.aggregate([
            { $match: { 
                ownerId, 
                createdAt: { $gte: startDate, $lte: endDate },
                status: 'completed'
            } },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);

        return result.length > 0 ? result[0].total : 0;
    }

    async getAllByDateRange(ownerId, startDate, endDate) {
        const docs = await this.model.find({
            ownerId,
            createdAt: { $gte: startDate, $lte: endDate }
        }).sort({ createdAt: -1 });

        return docs.map(doc => {
            const sale = new Sale({ id: doc._id.toString(), ...doc.toJSON() });
            return sale.toJSON();
        });
    }

    async getAll(ownerId, limit = null, lastId = null) {
        const query = { ownerId };
        if (lastId) {
            query._id = { $lt: lastId }; // Sorting by desc, so next items are "less than"
        }

        let mongoQuery = this.model.find(query).sort({ createdAt: -1 });
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        return docs.map(doc => new Sale({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
    }

    async getById(id, ownerId, session = null) {
        const doc = await this.model.findOne({ _id: id, ownerId }).session(session);
        if (!doc) return null;
        return new Sale({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async getByCustomer(customerId, ownerId, limit = null, lastId = null) {
        const query = { ownerId, customerId };
        if (lastId) query._id = { $lt: lastId };

        let mongoQuery = this.model.find(query).sort({ createdAt: -1 });
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        return docs.map(doc => new Sale({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
    }

    async create(saleData, session = null) {
        const now = new Date().toISOString();
        const items = (saleData.items || []).map(item => {
            const quantity = item.quantity || 0;
            const unitPrice = item.unitPrice || item.price || 0;
            return {
                ...item,
                productName: item.productName || item.name || 'Unknown Product',
                unitPrice,
                subtotal: item.subtotal || (quantity * unitPrice)
            };
        });

        const data = {
            _id: saleData.id || saleData._id || uuidv4(),
            ...saleData,
            items,
            createdAt: now,
            updatedAt: now
        };
        delete data.id;

        const [doc] = await this.model.create([data], { session });
        return new Sale({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async update(id, saleData, ownerId, session = null) {
        const updateData = {
            ...saleData,
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
        return new Sale({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async delete(id, ownerId, session = null) {
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        return result.deletedCount > 0;
    }
}

module.exports = MongoSaleRepository;
