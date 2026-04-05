const mongoose = require('mongoose');

const PurchaseItemSchema = new mongoose.Schema({
    productId: { type: String, required: true },
    productName: { type: String, required: true, alias: 'name' },
    quantity: { type: Number, required: true },
    costPrice: { type: Number, required: true, alias: 'price' },
    subtotal: { type: Number, required: true }
}, { _id: false });

const PurchaseSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    supplierId: { type: String, required: true },
    supplierName: { type: String, default: '' },
    invoiceNumber: { type: String, default: '' },
    purchaseDate: { type: String, index: true },
    items: [PurchaseItemSchema],
    subtotal: { type: Number, default: 0 },
    tax: { type: Number, default: 0 },
    totalAmount: { type: Number, required: true },
    amountPaid: { type: Number, default: 0 },
    remaining: { type: Number, default: 0 },
    status: { type: String, default: 'pending' },
    notes: { type: String, default: '' },
    createdAt: { type: String, index: true },
    updatedAt: { type: String }
}, {
    _id: false,
    timestamps: false
});

PurchaseSchema.index({ ownerId: 1, createdAt: -1 });
PurchaseSchema.index({ ownerId: 1, purchaseDate: -1 });

PurchaseSchema.virtual('id').get(function() {
    return this._id;
});

PurchaseSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Purchase', PurchaseSchema);
