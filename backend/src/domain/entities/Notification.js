// The AppNotification entity represents a message or alert sent to the shop owner.
class AppNotification {
    constructor({ 
        id, 
        type, // 'warning' (low stock), 'success' (sale made), 'alert' (debt due)
        title, 
        message, 
        isRead, // Whether the owner has seen this notification
        createdAt 
    }) {
        this.id = id;
        this.type = type || 'info'; // 'warning', 'success', 'info', 'alert', 'delivery'
        this.title = title || '';
        this.message = message || '';
        this.isRead = isRead || false;
        this.createdAt = createdAt || new Date().toISOString();
    }

    toJSON() {
        return {
            id: this.id,
            type: this.type,
            title: this.title,
            message: this.message,
            isRead: this.isRead,
            createdAt: this.createdAt,
        };
    }
}

module.exports = AppNotification;
