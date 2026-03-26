const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const PurchaseItemSchema = new mongoose.Schema({
    productId: { type: String, required: true },
    productName: { type: String, required: true },
    quantity: { type: Number, required: true },
    costPrice: { type: Number, required: true },
    subtotal: { type: Number, required: true }
}, { _id: false });

const PurchaseSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    supplierId: { type: String, required: true },
    supplierName: { type: String, default: '' },
    invoiceNumber: { type: String, default: '' },
    purchaseDate: { type: String },
    items: [PurchaseItemSchema],
    subtotal: { type: Number, default: 0 },
    tax: { type: Number, default: 0 },
    totalAmount: { type: Number, required: true },
    amountPaid: { type: Number, default: 0 },
    remaining: { type: Number, default: 0 },
    status: { type: String, default: 'pending' },
    notes: { type: String, default: '' },
    createdAt: { type: String },
    updatedAt: { type: String }
}, { _id: false, timestamps: false });

const PurchaseModel = mongoose.model('PurchaseTest', PurchaseSchema);

async function testValidation() {
    const data = {
        _id: uuidv4(),
        ownerId: 'owner123',
        supplierId: 'sup123',
        totalAmount: 100,
        items: [
            {
                productId: 'prod123',
                name: 'Test Product', // Incorrect field name (should be productName)
                quantity: 1,
                costPrice: 100
                // Missing subtotal
            }
        ]
    };

    try {
        const doc = new PurchaseModel(data);
        await doc.validate();
        console.log('Validation passed!');
    } catch (error) {
        console.error('Validation failed:', error.message);
    }
}

testValidation();
