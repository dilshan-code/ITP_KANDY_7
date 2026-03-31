const mongoose = require('mongoose');

const FeedbackSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    ownerName: { type: String, default: 'Unknown User' },
    category: { type: String, required: true }, // 'Feedback', 'Error', 'Improvement'
    message: { type: String, required: true },
    createdAt: { type: String, required: true }
}, {
    _id: false,
    timestamps: false
});

FeedbackSchema.virtual('id').get(function() {
    return this._id;
});

FeedbackSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Feedback', FeedbackSchema);
