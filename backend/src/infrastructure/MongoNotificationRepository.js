const { v4: uuidv4 } = require('uuid');
const NotificationModel = require('./models/Notification');
const AppNotification = require('../domain/entities/Notification');
const INotificationRepository = require('../domain/repositories/INotificationRepository');

class MongoNotificationRepository extends INotificationRepository {
    constructor() {
        super();
        this.model = NotificationModel;
    }

    async getAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docs = await this.model.find({ ownerId }).sort({ createdAt: -1 });
        return docs.map(doc => {
            const notification = new AppNotification({ id: doc._id.toString(), ...doc.toJSON() });
            return notification.toJSON();
        });
    }

    async create(notificationData, session = null) {
        if (!notificationData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const data = {
            _id: notificationData.id || notificationData._id || uuidv4(),
            ...notificationData,
            isRead: false,
            createdAt: now,
            updatedAt: now
        };
        delete data.id; // Ensure we use _id for Mongoose

        const [doc] = await this.model.create([data], { session });
        return { id: doc._id.toString(), ...doc.toJSON() };
    }

    async markAsRead(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.updateOne(
            { _id: id, ownerId },
            { $set: { isRead: true } }
        );
        return result.modifiedCount > 0;
    }

    async markAllAsRead(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        await this.model.updateMany(
            { ownerId, isRead: false },
            { $set: { isRead: true } }
        );
        return true;
    }

    async delete(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const result = await this.model.deleteOne({ _id: id, ownerId });
        return result.deletedCount > 0;
    }

    async deleteAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        await this.model.deleteMany({ ownerId });
        return true;
    }
}

module.exports = MongoNotificationRepository;
