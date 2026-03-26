const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    category: { type: String, default: 'General' },
    sellingPrice: { type: Number, required: true },
    purchasePrice: { type: Number, default: 0 },
    stockQuantity: { type: Number, default: 0 },
    minimumStockLevel: { type: Number, default: 5 },
    isLowStock: { type: Boolean, default: false },
    description: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
    unit: { type: String, default: 'ea' },
    notifyOutOfStock: { type: Boolean, default: true },
    createdAt: { type: String },
    updatedAt: { type: String }
}, {
    _id: false, // Tell Mongoose we are providing the _id
    timestamps: false
});

ProductSchema.virtual('id').get(function() {
    return this._id;
});

ProductSchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Product', ProductSchema);
