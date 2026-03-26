const mongoose = require('mongoose');

const SaleItemSchema = new mongoose.Schema({
    productId: { type: String, required: true },
    productName: { type: String, required: true, alias: 'name' },
    quantity: { type: Number, required: true },
    unitPrice: { type: Number, required: true, alias: 'price' },
    purchasePrice: { type: Number, required: true, default: 0 },
    subtotal: { type: Number, required: true },
    unit: { type: String, default: 'ea' }
}, { _id: false });

const SaleSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    items: [SaleItemSchema],
    customerId: { type: String, default: '' },
    customerName: { type: String, default: 'Walk-in Customer' },
    subtotal: { type: Number, required: true },
    totalAmount: { type: Number, required: true },
    paymentMethod: { type: String, default: 'cash' },
    status: { type: String, default: 'completed' },
    createdAt: { type: String },
    updatedAt: { type: String }
}, {
    _id: false,
    timestamps: false
});

SaleSchema.virtual('id').get(function() {
    return this._id;
});

SaleSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Sale', SaleSchema);
