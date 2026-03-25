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
        const snapshot = await this.collection.where('ownerId', '==', ownerId).get();
        const notifications = snapshot.docs.map(doc => {
            const notification = new AppNotification({ id: doc.id, ...doc.data() });
            return notification.toJSON();
        });
        // Sort in-memory by createdAt descending
        return notifications.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    async create(notificationData, transaction = null) {
        if (!notificationData.ownerId) throw new Error('Owner ID is required');
        const now = new Date().toISOString();
        const dataToSave = {
            ownerId: notificationData.ownerId,
            type: notificationData.type || 'info', // 'info', 'warning', 'error', 'success'
            title: notificationData.title,
            message: notificationData.message,
            isRead: false,
            createdAt: now,
        };

        if (transaction) {
            const docRef = this.collection.doc();
            transaction.set(docRef, dataToSave);
            return { id: docRef.id, ...dataToSave };
        } else {
            const docRef = await this.collection.add(dataToSave);
            return { id: docRef.id, ...dataToSave };
        }
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
