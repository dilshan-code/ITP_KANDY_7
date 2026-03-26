const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

// Mock Models
const ProductSchema = new mongoose.Schema({
    _id: { type: String, required: true },
    ownerId: { type: String, required: true, index: true },
    name: { type: String, required: true },
    stockQuantity: { type: Number, default: 0 },
    minimumStockLevel: { type: Number, default: 5 },
}, { _id: false });
const ProductModel = mongoose.model('ProductTest', ProductSchema);

async function testStockUpdate() {
    await mongoose.connect('mongodb://localhost:27017/test_stock_update');
    await ProductModel.deleteMany({});

    const productId = uuidv4();
    const ownerId = 'owner123';

    // Create initial product
    await ProductModel.create({
        _id: productId,
        ownerId,
        name: 'Test Product',
        stockQuantity: 5,
        minimumStockLevel: 2
    });

    console.log('Initial stock: 5');

    const session = await mongoose.startSession();
    try {
        session.startTransaction();

        // Simulate fetching product
        const doc = await ProductModel.findOne({ _id: productId, ownerId }).session(session);
        const product = { id: doc._id, stockQuantity: doc.stockQuantity, minimumStockLevel: doc.minimumStockLevel };

        // Simulate purchase item
        const item = { productId, quantity: 10 };

        // Update stock
        const newStock = (product.stockQuantity || 0) + (item.quantity || 0);
        console.log(`Calculated new stock: ${newStock}`);

        await ProductModel.findOneAndUpdate(
            { _id: productId, ownerId },
            { $set: { stockQuantity: newStock, updatedAt: new Date().toISOString() } },
            { new: true, session }
        );

        await session.commitTransaction();
        console.log('Transaction committed.');
    } catch (error) {
        console.error('Error:', error);
        await session.abortTransaction();
    } finally {
        session.endSession();
    }

    // Verify
    const finalProduct = await ProductModel.findOne({ _id: productId, ownerId });
    console.log('Final stock:', finalProduct.stockQuantity);

    await mongoose.disconnect();
}

testStockUpdate();
