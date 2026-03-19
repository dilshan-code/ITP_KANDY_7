const { v4: uuidv4 } = require('uuid');
const Product = require('../domain/entities/Product');
const IProductRepository = require('../domain/repositories/IProductRepository');

class InMemoryProductRepository extends IProductRepository {
    constructor() {
        super();
        this.products = new Map();
        this._seed();
    }

    _seed() {
        const seedData = [
            {
                id: uuidv4(),
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
                id: uuidv4(),
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
                id: uuidv4(),
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
                id: uuidv4(),
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
                id: uuidv4(),
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

        for (const data of seedData) {
            const product = new Product(data);
            this.products.set(product.id, product);
        }
    }

    async getAll() {
        return Array.from(this.products.values()).map(p => p.toJSON());
    }

    async getById(id) {
        const product = this.products.get(id);
        if (!product) return null;
        return product.toJSON();
    }

    async create(productData) {
        const product = new Product({
            id: uuidv4(),
            ...productData,
        });
        this.products.set(product.id, product);
        return product.toJSON();
    }

    async update(id, productData) {
        const existing = this.products.get(id);
        if (!existing) return null;

        const updated = new Product({
            ...existing,
            ...productData,
            id: existing.id,
            createdAt: existing.createdAt,
            updatedAt: new Date().toISOString(),
        });
        this.products.set(id, updated);
        return updated.toJSON();
    }

    async delete(id) {
        const existed = this.products.has(id);
        this.products.delete(id);
        return existed;
    }
}

module.exports = InMemoryProductRepository;
