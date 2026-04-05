const mongoose = require('mongoose');

const OwnerSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    name: { type: String, required: true },
    shopName: { type: String, required: true },
    phone: { type: String, required: true, unique: true },
    email: { type: String, default: '', index: true },
    password: { type: String, required: true },
    role: { type: String, default: 'owner' },
    status: { type: String, default: 'approved' },
    isSuspended: { type: Boolean, default: false },
    createdAt: { type: String },
    updatedAt: { type: String }
}, {
    timestamps: false
});

OwnerSchema.virtual('id').get(function() {
    return this._id;
});

OwnerSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Owner', OwnerSchema);
