// Retrieves all system alerts and notifications.
class GetAllNotifications {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute() { return this.notificationRepository.getAll(); }
}

// Creates a new alert (e.g., when stock is low).
class CreateNotification {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(notificationData) { return this.notificationRepository.create(notificationData); }
}

// Marks a single alert as "read" by the owner.
class MarkNotificationAsRead {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(id) { return this.notificationRepository.markAsRead(id); }
}

class MarkAllNotificationsAsRead {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute() { return this.notificationRepository.markAllAsRead(); }
}

class DeleteNotification {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute(id) { return this.notificationRepository.delete(id); }
}

// Clears all alerts from the owner's notification tray.
class DeleteAllNotifications {
    constructor(notificationRepository) { this.notificationRepository = notificationRepository; }
    async execute() { return this.notificationRepository.deleteAll(); }
}

module.exports = { GetAllNotifications, CreateNotification, MarkNotificationAsRead, MarkAllNotificationsAsRead, DeleteNotification, DeleteAllNotifications };
