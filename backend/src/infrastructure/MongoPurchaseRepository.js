const { v4: uuidv4 } = require('uuid');
const PurchaseModel = require('./models/Purchase');
const Purchase = require('../domain/entities/Purchase');
const IPurchaseRepository = require('../domain/repositories/IPurchaseRepository');

class MongoPurchaseRepository extends IPurchaseRepository {
    constructor() {
        super();
        this.model = PurchaseModel;
    }

    async getTotalPurchases(ownerId) {
        const result = await this.model.aggregate([
            { $match: { ownerId } },
            { $group: { _id: null, total: { $sum: "$totalAmount" } } }
        ]);
        return result.length > 0 ? result[0].total : 0;
    }

    async getAllByDateRange(ownerId, startDate, endDate) {
        const docs = await this.model.find({
            ownerId,
            createdAt: { $gte: startDate, $lte: endDate }
        }).sort({ createdAt: -1 });

        return docs.map(doc => new Purchase({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
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
        return docs.map(doc => new Purchase({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
    }

    async getById(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.model.findOne({ _id: id, ownerId }).session(session);
        if (!doc) return null;
        return new Purchase({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async create(purchaseData, session = null) {
        if (!purchaseData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const remaining = (purchaseData.totalAmount || 0) - (purchaseData.amountPaid || 0);
        let status = 'pending';
        if (remaining <= 0) status = 'paid';
        else if (purchaseData.amountPaid > 0) status = 'partial';

        const items = (purchaseData.items || []).map(item => {
            const quantity = item.quantity || 0;
            const costPrice = item.costPrice || item.price || 0;
            return {
                ...item,
                productName: item.productName || item.name || 'Unknown Product',
                costPrice,
                subtotal: item.subtotal || (quantity * costPrice)
            };
        });

        // Auto-generate invoice number if not provided
        if (!purchaseData.invoiceNumber || purchaseData.invoiceNumber.trim() === '') {
            const date = new Date();
            const datePart = date.toISOString().split('T')[0].replace(/-/g, ''); // YYYYMMDD
            const randomPart = Math.floor(1000 + Math.random() * 9000); // 4-digit random
            purchaseData.invoiceNumber = `INV-${datePart}-${randomPart}`;
        }

        const data = {
            _id: purchaseData.id || purchaseData._id || uuidv4(),
            ...purchaseData,
            items,
            remaining,
            status,
            createdAt: now,
            updatedAt: now
        };
        delete data.id;

        const [doc] = await this.model.create([data], { session });
        return new Purchase({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async getBySupplier(supplierId, ownerId, limit = null, lastId = null) {
        if (!ownerId) throw new Error('Owner ID is required');

        const query = { ownerId, supplierId };
        if (lastId) query._id = { $lt: lastId };

        let mongoQuery = this.model.find(query).sort({ createdAt: -1 });
        if (limit) mongoQuery = mongoQuery.limit(parseInt(limit));

        const docs = await mongoQuery.exec();
        return docs.map(doc => new Purchase({ id: doc._id.toString(), ...doc.toJSON() }).toJSON());
    }

    async update(id, purchaseData, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const updateData = { ...purchaseData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        const doc = await this.model.findOneAndUpdate(
            { _id: id, ownerId },
            { $set: updateData },
            { new: true, session }
        );

        if (!doc) return null;
        return new Purchase({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async delete(id, ownerId, session = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.deleteOne({ _id: id, ownerId }).session(session);
        return result.deletedCount > 0;
    }
}

module.exports = MongoPurchaseRepository;
