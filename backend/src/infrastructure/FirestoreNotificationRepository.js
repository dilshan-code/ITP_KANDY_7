const { db } = require('../config/firebaseAdmin');
const AppNotification = require('../domain/entities/Notification');
const INotificationRepository = require('../domain/repositories/INotificationRepository');

class FirestoreNotificationRepository extends INotificationRepository {
    constructor() {
        super();
        this.collection = db.collection('notifications');
    }

    async getAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection.where('ownerId', '==', ownerId).orderBy('createdAt', 'desc').get();
        return snapshot.docs.map(doc => {
            const notification = new AppNotification({ id: doc.id, ...doc.data() });
            return notification.toJSON();
        });
    }

    async create(notificationData) {
        if (!notificationData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const dataToSave = {
            ownerId: notificationData.ownerId,
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

    async markAsRead(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        
        const data = doc.data();
        if (data.ownerId !== ownerId) return false;

        await docRef.update({ isRead: true });
        return true;
    }

    async markAllAsRead(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .where('isRead', '==', false)
            .get();
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.update(doc.ref, { isRead: true });
        });
        await batch.commit();
        return true;
    }

    async delete(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;
        
        const data = doc.data();
        if (data.ownerId !== ownerId) return false;

        await docRef.delete();
        return true;
    }

    async deleteAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const snapshot = await this.collection.where('ownerId', '==', ownerId).get();
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        return true;
    }
}

module.exports = FirestoreNotificationRepository;
