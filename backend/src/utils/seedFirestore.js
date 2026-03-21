/**
 * One-time script to seed the Firestore database with initial product data.
 * Run: node src/utils/seedFirestore.js
 */
const { db } = require('../config/firebaseAdmin');

const seedProducts = [
    {
        name: 'Fresh Orange',
        category: 'Fruits',
        sellingPrice: 2.99,
        costPrice: 1.80,
        stockQuantity: 4,
        minimumStockLevel: 10,
        description: 'Juicy fresh oranges sourced from premium orchards. Rich in Vitamin C and perfect for juicing or snacking.',
        imageUrl: 'https://images.unsplash.com/photo-1547514701-42782101795e?w=400',
        unit: 'kg',
    },
    {
        name: 'Organic Broccoli',
        category: 'Vegetables',
        sellingPrice: 4.50,
        costPrice: 3.00,
        stockQuantity: 32,
        minimumStockLevel: 10,
        description: 'Fresh organic broccoli, locally sourced. High in fiber, vitamins, and antioxidants.',
        imageUrl: 'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=400',
        unit: 'ea',
    },
    {
        name: 'Organic Red Apples',
        category: 'Fruits & Vegetables',
        sellingPrice: 240.00,
        costPrice: 180.00,
        stockQuantity: 45,
        minimumStockLevel: 10,
        description: 'Fresh seasonal red apples sourced directly from local organic farms. High in fiber and Vitamin C. Hand-picked and sorted for quality.',
        imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400',
        unit: 'kg',
    },
    {
        name: 'Whole Wheat Bread',
        category: 'Bakery',
        sellingPrice: 3.49,
        costPrice: 2.00,
        stockQuantity: 18,
        minimumStockLevel: 5,
        description: 'Freshly baked whole wheat bread. High in fiber and made with natural ingredients.',
        imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400',
        unit: 'ea',
    },
    {
        name: 'Farm Fresh Eggs',
        category: 'Dairy & Eggs',
        sellingPrice: 5.99,
        costPrice: 3.50,
        stockQuantity: 6,
        minimumStockLevel: 12,
        description: 'Free-range farm fresh eggs. Rich in protein and omega-3 fatty acids.',
        imageUrl: 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400',
        unit: 'dozen',
    },
];

async function seed() {
    console.log('🌱 Seeding Firestore with product data...\n');

    const collection = db.collection('products');

    // Check if products already exist
    const existing = await collection.get();
    if (!existing.empty) {
        console.log(`⚠️  Products collection already has ${existing.size} documents.`);
        console.log('   Delete them manually in Firebase Console if you want to re-seed.\n');

        // List existing products
        existing.docs.forEach(doc => {
            console.log(`   - ${doc.data().name} (${doc.id})`);
        });
        process.exit(0);
    }

    const now = new Date().toISOString();

    for (const product of seedProducts) {
        const docRef = await collection.add({
            ...product,
            createdAt: now,
            updatedAt: now,
        });
        console.log(`   ✅ Added: ${product.name} (ID: ${docRef.id})`);
    }

    console.log(`\n🎉 Successfully seeded ${seedProducts.length} products into Firestore!`);
    process.exit(0);
}

seed().catch(error => {
    console.error('❌ Seeding failed:', error.message);
    process.exit(1);
});
