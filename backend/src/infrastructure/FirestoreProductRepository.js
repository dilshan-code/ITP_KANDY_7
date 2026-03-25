// Import the Firestore database connection
const { db } = require('../config/firebaseAdmin');
// Import our core Product entity
const Product = require('../domain/entities/Product');
// Import the interface this class must follow
const IProductRepository = require('../domain/repositories/IProductRepository');

// This class handles all direct communication with the Firestore database
// for the 'products' collection.
class FirestoreProductRepository extends IProductRepository {
    constructor() {
        super();
        // Get a reference to the 'products' collection in Firestore
        this.collection = db.collection('products');
    }

    // Fetch all products from the database for a specific owner
    async getAll(ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        // Execute a 'get' query against products matching this ownerId
        const snapshot = await this.collection.where('ownerId', '==', ownerId).get();
        // Loop over the snapshot documents, converting each to a domain Product object, then to a JSON map
        return snapshot.docs.map(doc => {
            const data = doc.data();
            const product = new Product({ id: doc.id, ...data });
            return product.toJSON();
        });
    }

    async getLowStockCount(ownerId) {
        const snapshot = await this.collection
            .where('ownerId', '==', ownerId)
            .where('isLowStock', '==', true)
            .count()
            .get();
        return snapshot.data().count;
    }

    // Fetch a single product by its unique string ID and owner ID
    async getById(id, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = transaction ? await transaction.get(docRef) : await docRef.get();
        if (!doc.exists) return null;
        const data = doc.data();
        if (data.ownerId !== ownerId) return null;
        const product = new Product({ id: doc.id, ...data });
        return product.toJSON();
    }

    // Save a new product to the database
    async create(productData, transaction = null) {
        if (!productData.ownerId) throw new Error('Owner ID is required');
        
        const now = new Date().toISOString();
        const isLowStock = productData.stockQuantity <= productData.minimumStockLevel;
        const dataToSave = {
            ownerId: productData.ownerId,
            name: productData.name,
            category: productData.category,
            sellingPrice: productData.sellingPrice,
            stockQuantity: productData.stockQuantity,
            minimumStockLevel: productData.minimumStockLevel,
            isLowStock: isLowStock,
            description: productData.description || '',
            imageUrl: productData.imageUrl || '',
            unit: productData.unit || 'ea',
            notifyOutOfStock: productData.notifyOutOfStock !== undefined ? productData.notifyOutOfStock : true,
            createdAt: now,
            updatedAt: now,
        };

        let docRef;
        if (transaction) {
            docRef = this.collection.doc(); // Firestore generates ID client-side for transactions
            transaction.set(docRef, dataToSave);
        } else {
            docRef = await this.collection.add(dataToSave);
        }
        
        const product = new Product({ id: docRef.id, ...dataToSave });
        return product.toJSON();
    }

    // Update an existing product
    async update(id, productData, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        
        const updateData = { ...productData, updatedAt: new Date().toISOString() };
        delete updateData.id;
        delete updateData.ownerId;

        if (transaction) {
            // In a transaction, we assume the use case has handled the isLowStock calculation if needed,
            // or we'll have to fetch it here. For simplicity, the use case should pass it if stockQuantity changed.
            transaction.update(docRef, updateData);
            return { id, ...updateData };
        } else {
            const doc = await docRef.get();
            if (!doc.exists) return null;
            const existingData = doc.data();
            if (existingData.ownerId !== ownerId) return null;

            // Recalculate isLowStock if stock info changed
            const stock = updateData.stockQuantity !== undefined ? updateData.stockQuantity : existingData.stockQuantity;
            const min = updateData.minimumStockLevel !== undefined ? updateData.minimumStockLevel : existingData.minimumStockLevel;
            updateData.isLowStock = stock <= min;

            await docRef.update(updateData);
            const updatedDoc = await docRef.get();
            return new Product({ id: updatedDoc.id, ...updatedDoc.data() }).toJSON();
        }
    }

    // Delete a product from the database
    async delete(id, ownerId, transaction = null) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        
        if (transaction) {
            transaction.delete(docRef);
            return true;
        } else {
            const doc = await docRef.get();
            if (!doc.exists) return false;

            const existingData = doc.data();
            if (existingData.ownerId !== ownerId) return false;

            await docRef.delete();
            return true;
        }
    }
}

module.exports = FirestoreProductRepository;
