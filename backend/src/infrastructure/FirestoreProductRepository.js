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

    // Fetch a single product by its unique string ID and owner ID
    async getById(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;

        const data = doc.data();
        if (data.ownerId !== ownerId) return null; // Security check

        const product = new Product({ id: doc.id, ...data });
        return product.toJSON();
    }

    // Save a new product to the database
    async create(productData) {
        if (!productData.ownerId) throw new Error('Owner ID is required');
        
        const now = new Date().toISOString();
        const dataToSave = {
            ownerId: productData.ownerId,
            name: productData.name,
            category: productData.category,
            sellingPrice: productData.sellingPrice,
            stockQuantity: productData.stockQuantity,
            minimumStockLevel: productData.minimumStockLevel,
            description: productData.description || '',
            imageUrl: productData.imageUrl || '',
            unit: productData.unit || 'ea',
            notifyOutOfStock: productData.notifyOutOfStock !== undefined ? productData.notifyOutOfStock : true,
            createdAt: now,
            updatedAt: now,
        };

        const docRef = await this.collection.add(dataToSave);
        const product = new Product({ id: docRef.id, ...dataToSave });
        return product.toJSON();
    }

    // Update an existing product
    async update(id, productData, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;
        
        const existingData = doc.data();
        if (existingData.ownerId !== ownerId) return null; // Security check

        const updateData = {
            ...productData,
            updatedAt: new Date().toISOString(),
        };

        delete updateData.id;
        delete updateData.ownerId; // Do not allow changing owner

        await docRef.update(updateData);

        const updatedDoc = await docRef.get();
        const product = new Product({ id: updatedDoc.id, ...updatedDoc.data() });
        return product.toJSON();
    }

    // Delete a product from the database
    async delete(id, ownerId) {
        if (!ownerId) throw new Error('Owner ID is required');
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;

        const existingData = doc.data();
        if (existingData.ownerId !== ownerId) return false; // Security check

        await docRef.delete();
        return true;
    }
}

module.exports = FirestoreProductRepository;
