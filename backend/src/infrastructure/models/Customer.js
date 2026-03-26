const mongoose = require('mongoose');

const CustomerSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    phone: { type: String, default: '' },
    totalOutstanding: { type: Number, default: 0 },
    creditLimit: { type: Number, default: 5000 },
    status: { type: String, default: 'active' },
    imageUrl: { type: String, default: '' },
    createdAt: { type: String },
    updatedAt: { type: String }
}, {
    _id: false,
    timestamps: false
});

CustomerSchema.virtual('id').get(function() {
    return this._id;
});

CustomerSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Customer', CustomerSchema);
