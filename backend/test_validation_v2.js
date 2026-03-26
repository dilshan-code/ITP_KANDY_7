const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

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

const PurchaseModel = mongoose.model('PurchaseTest2', PurchaseSchema);

async function testValidation() {
    // This simulates the mapping done in MongoPurchaseRepository
    const rawData = {
        _id: uuidv4(),
        ownerId: 'owner123',
        supplierId: 'sup123',
        totalAmount: 100,
        items: [
            {
                productId: 'prod123',
                name: 'Test Product', // Will be mapped to productName
                quantity: 1,
                price: 100 // Will be mapped to costPrice
            }
        ]
    };

    const items = rawData.items.map(item => ({
        ...item,
        productName: item.productName || item.name,
        costPrice: item.costPrice || item.price,
        subtotal: item.subtotal || (item.quantity * (item.costPrice || item.price))
    }));

    const data = {
        ...rawData,
        items
    };

    try {
        const doc = new PurchaseModel(data);
        await doc.validate();
        console.log('Validation passed!');
        console.log('Document:', JSON.stringify(doc.toJSON(), null, 2));
    } catch (error) {
        console.error('Validation failed:', error.message);
    }
}

testValidation();
