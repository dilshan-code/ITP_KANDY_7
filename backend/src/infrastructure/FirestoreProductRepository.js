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

    // Fetch all products from the database
    async getAll() {
        // Execute a 'get' query against the entire 'products' Firestore collection
        const snapshot = await this.collection.get();
        // Loop over the snapshot documents, converting each to a domain Product object, then to a JSON map
        return snapshot.docs.map(doc => {
            // Extract the raw fields (name, price, etc.) stored in the Firestore document
            const data = doc.data();
            // Instantiate our Product class, merging the document ID with its raw data fields
            const product = new Product({ id: doc.id, ...data });
            // Return only the generic JSON representation (hiding internal class methods)
            return product.toJSON();
        });
    }

    // Fetch a single product by its unique string ID
    async getById(id) {
        const doc = await this.collection.doc(id).get();
        // If it doesn't exist, return null
        if (!doc.exists) return null;

        const product = new Product({ id: doc.id, ...doc.data() });
        return product.toJSON();
    }

    // Save a new product to the database
    async create(productData) {
        // Generate an ISO string timestamp to mark when this record was created
        const now = new Date().toISOString();
        const dataToSave = {
            name: productData.name,
            category: productData.category,
            sellingPrice: productData.sellingPrice,
            costPrice: productData.costPrice,
            stockQuantity: productData.stockQuantity,
            minimumStockLevel: productData.minimumStockLevel,
            description: productData.description || '',
            imageUrl: productData.imageUrl || '',
            unit: productData.unit || 'ea',
            createdAt: now,
            updatedAt: now, // updated and created are the same initially
        };

        // .add() creates a new document inside the 'products' collection and auto-generates a unique string ID
        const docRef = await this.collection.add(dataToSave);
        // Create the product entity wrapper to trigger any calculated fields (like isLowStock), and return it
        const product = new Product({ id: docRef.id, ...dataToSave });
        return product.toJSON();
    }

    // Update an existing product
    async update(id, productData) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return null;

        const updateData = {
            ...productData,
            updatedAt: new Date().toISOString(),
        };

        // Remove id if present in update data (shouldn't update the doc ID itself)
        delete updateData.id;

        // Save changes to Firestore
        await docRef.update(updateData);

        // Fetch updated document to return the final state
        const updatedDoc = await docRef.get();
        const product = new Product({ id: updatedDoc.id, ...updatedDoc.data() });
        return product.toJSON();
    }

    // Delete a product from the database
    async delete(id) {
        const docRef = this.collection.doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return false;

        // Delete the document
        await docRef.delete();
        return true;
    }
}

module.exports = FirestoreProductRepository;
