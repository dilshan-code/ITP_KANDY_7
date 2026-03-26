const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    type: { type: String, default: 'info' },
    title: { type: String, required: true },
    message: { type: String, required: true },
    isRead: { type: Boolean, default: false },
    createdAt: { type: String },
    updatedAt: { type: String }
}, {
    _id: false,
    timestamps: false
});

NotificationSchema.virtual('id').get(function() {
    return this._id;
});

NotificationSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Notification', NotificationSchema);
