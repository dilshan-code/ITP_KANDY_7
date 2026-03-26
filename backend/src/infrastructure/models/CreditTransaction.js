const mongoose = require('mongoose');

const CreditTransactionSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    customerId: { type: String, required: true },
    customerName: { type: String, default: '' },
    type: { type: String, required: true }, // 'credit', 'payment'
    title: { type: String, default: '' },
    amount: { type: Number, required: true },
    date: { type: String },
    createdAt: { type: String },
    updatedAt: { type: String }
}, {
    _id: false,
    timestamps: false
});

CreditTransactionSchema.virtual('id').get(function() {
    return this._id;
});

CreditTransactionSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('CreditTransaction', CreditTransactionSchema);
