const { db } = require('../config/firebaseAdmin');
const Sale = require('../domain/entities/Sale');
const ISaleRepository = require('../domain/repositories/ISaleRepository');

// Handles all direct communication with Firestore for the 'sales' collection
class FirestoreSaleRepository extends ISaleRepository {
    constructor() {
        super();
        this.collection = db.collection('sales');
    }

    // Fetch all sales, newest first
    async getAll() {
        const snapshot = await this.collection
            .orderBy('createdAt', 'desc')
            .get();

        const sales = [];
        for (const doc of snapshot.docs) {
            const data = doc.data();
            // Also fetch sub-collection items for each sale
            const itemsSnap = await this.collection
                .doc(doc.id)
                .collection('saleItems')
                .get();
            const items = itemsSnap.docs.map(i => i.data());
            const sale = new Sale({ id: doc.id, ...data, items });
            sales.push(sale.toJSON());
        }
        return sales;
    }

    // Fetch a single sale with its items
    async getById(id) {
        const doc = await this.collection.doc(id).get();
        if (!doc.exists) return null;

        const itemsSnap = await this.collection
            .doc(id)
            .collection('saleItems')
            .get();
        const items = itemsSnap.docs.map(i => i.data());

        const sale = new Sale({ id: doc.id, ...doc.data(), items });
        return sale.toJSON();
    }

    // Create a new sale and its items as sub-collection
    async create(saleData) {
        const now = new Date().toISOString();

        // Build the parent sale document
        const dataToSave = {
            saleId: saleData.id || '',         // flutter ගෙන් එන saleId (optional)
            invoiceId: saleData.invoiceId || '',
            customerName: saleData.customerName || 'Walk-in Customer',
            isCredit: saleData.isCredit || false,
            status: saleData.status || 'Completed',
            subtotal: saleData.subtotal || 0,
            tax: saleData.tax || 0,
            totalAmount: saleData.totalAmount || 0,
            date: saleData.date || now,
            createdAt: now,
            updatedAt: now,
        };

        // Save parent document
        const docRef = await this.collection.add(dataToSave);

        // Save each sale item as a sub-collection document
        const items = saleData.items || [];
        for (const item of items) {
            await docRef.collection('saleItems').add({
                productId: item.productId || '',
                productName: item.productName || '',
                quantity: item.quantity || 0,
                unitPrice: item.unitPrice || 0,
                subTotal: item.subTotal || (item.unitPrice * item.quantity) || 0,
            });

            // ───────────────────────────────────────────────────────────────
            // Stock deduction — reduce stockQuantity in 'products' collection
            // This links ours (Sales) with Gunawardana's (Product Management)
            // ───────────────────────────────────────────────────────────────
            if (item.productId) {
                const productRef = db.collection('products').doc(item.productId);
                const productDoc = await productRef.get();
                if (productDoc.exists) {
                    const currentStock = productDoc.data().stockQuantity || 0;
                    const newStock = Math.max(0, currentStock - item.quantity);
                    await productRef.update({
                        stockQuantity: newStock,
                        updatedAt: now,
                    });
                }
            }
        }

        // If credit sale — update customers collection (Disanayaka's module)
        if (dataToSave.isCredit && dataToSave.customerName !== 'Walk-in Customer') {
            await this._upsertCreditCustomer(
                dataToSave.customerName,
                docRef.id,
                dataToSave.totalAmount,
                now
            );
        }

        // Return the saved sale with items
        const sale = new Sale({ id: docRef.id, ...dataToSave, items });
        return sale.toJSON();
    }

    // Helper — add/update customer credit record
    async _upsertCreditCustomer(customerName, saleId, amount, now) {
        const customersRef = db.collection('customers');
        const existing = await customersRef
            .where('name', '==', customerName)
            .get();

        const creditEntry = {
            saleId,
            date: now,
            totalAmount: amount,
            status: 'Unpaid',
            createdAt: now,
        };

        if (existing.empty) {
            // Create new customer
            const custRef = await customersRef.add({
                name: customerName,
                totalCredit: amount,
                createdAt: now,
                updatedAt: now,
            });
            await custRef.collection('creditSales').add(creditEntry);
        } else {
            // Update existing customer total credit
            const custDoc = existing.docs[0];
            const currentCredit = (custDoc.data().totalCredit || 0);
            await custDoc.reference.update({
                totalCredit: currentCredit + amount,
                updatedAt: now,
            });
            await custDoc.reference.collection('creditSales').add(creditEntry);
        }
    }

    // Fetch sales within a date range (for PDF report)
    async getSummaryByDateRange(from, to) {
        const snapshot = await this.collection
            .where('date', '>=', from)
            .where('date', '<=', to)
            .orderBy('date', 'desc')
            .get();

        return snapshot.docs.map(doc => {
            const sale = new Sale({ id: doc.id, ...doc.data() });
            return sale.toJSON();
        });
    }

    // Get total revenue (all completed sales)
    async getTotalRevenue() {
        const snapshot = await this.collection
            .where('status', '==', 'Completed')
            .get();
        return snapshot.docs.reduce(
            (sum, doc) => sum + (doc.data().totalAmount || 0),
            0
        );
    }
}

module.exports = FirestoreSaleRepository;
