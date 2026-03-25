// Retrieves all system alerts and notifications.
class GetAllNotifications {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(ownerId) { return this.notificationRepository.getAll(ownerId); }
}

// Creates a new alert (e.g., when stock is low).
class CreateNotification {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(notificationData, ownerId) { 
        if (!notificationData || !ownerId) throw new Error('Notification data and Owner ID are required');
        return this.notificationRepository.create({ ...notificationData, ownerId }); 
    }
}

// Marks a single alert as "read" by the owner.
class MarkNotificationAsRead {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(id, ownerId) { return this.notificationRepository.markAsRead(id, ownerId); }
}

class MarkAllNotificationsAsRead {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(ownerId) { return this.notificationRepository.markAllAsRead(ownerId); }
}

class DeleteNotification {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(id, ownerId) { return this.notificationRepository.delete(id, ownerId); }
}

// Clears all alerts from the owner's notification tray.
class DeleteAllNotifications {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(ownerId) { return this.notificationRepository.deleteAll(ownerId); }
}

module.exports = { GetAllNotifications, CreateNotification, MarkNotificationAsRead, MarkAllNotificationsAsRead, DeleteNotification, DeleteAllNotifications };
