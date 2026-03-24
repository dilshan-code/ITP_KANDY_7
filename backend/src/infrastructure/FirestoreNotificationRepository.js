const { db } = require('../config/firebaseAdmin');
const AppNotification = require('../domain/entities/Notification');
const INotificationRepository = require('../domain/repositories/INotificationRepository');

class FirestoreNotificationRepository extends INotificationRepository {
    constructor() {
        super();
        this.collection = db.collection('notifications');
    }

    async getAll() {
        const snapshot = await this.collection.orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const notification = new AppNotification({ id: doc.id, ...doc.data() });
            return notification.toJSON();
        });
    }

    async create(notificationData) {
        const now = new Date().toISOString();
        const dataToSave = {
            type: notificationData.type || 'info',
            title: notificationData.title || '',
            message: notificationData.message || '',
            isRead: false,
            createdAt: now,
        };
        const docRef = await this.collection.add(dataToSave);
        const notification = new AppNotification({ id: docRef.id, ...dataToSave });
        return notification.toJSON();
    }

    async markAsRead(id) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        await docRef.update({ isRead: true });
        return true;
    }

    async markAllAsRead() {
        const snapshot = await this.collection.where('isRead', '==', false).get();
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.update(doc.ref, { isRead: true });
        });
        await batch.commit();
        return true;
    }

    async delete(id) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        await docRef.delete();
        return true;
    }

    async deleteAll() {
        const snapshot = await this.collection.get();
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        return true;
    }
}

module.exports = FirestoreNotificationRepository;
