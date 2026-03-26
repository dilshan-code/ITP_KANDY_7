const mongoose = require('mongoose');

const SupplierSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    phone: { type: String, default: '' },
    address: { type: String, default: '' },
    email: { type: String, default: '' },
    notes: { type: String, default: '' },
    status: { type: String, default: 'active' },
    totalPayable: { type: Number, default: 0 },
    createdAt: { type: String },
    updatedAt: { type: String }
}, {
    _id: false,
    timestamps: false
});

SupplierSchema.virtual('id').get(function() {
    return this._id;
});

SupplierSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Supplier', SupplierSchema);
