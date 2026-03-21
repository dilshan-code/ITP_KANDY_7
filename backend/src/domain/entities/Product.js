// This is the core 'Product' domain entity. 
// It defines exactly what a Product looks like inside our application, 
// independent of any database or framework.
class Product {
  constructor({
    id,
    name,
    category,
    sellingPrice,
    costPrice,
    stockQuantity,
    minimumStockLevel,
    description,
    imageUrl,
    unit,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.name = name;
    this.category = category;
    this.sellingPrice = sellingPrice;
    this.costPrice = costPrice;
    this.stockQuantity = stockQuantity;
    this.minimumStockLevel = minimumStockLevel;
    // Set default values if not provided
    this.description = description || '';
    this.imageUrl = imageUrl || '';
    this.unit = unit || 'ea';
    this.createdAt = createdAt || new Date().toISOString();
    this.updatedAt = updatedAt || new Date().toISOString();
  }

  // A calculated field (getter) that dynamically checks if stock is too low
  get isLowStock() {
    return this.stockQuantity <= this.minimumStockLevel;
  }

  // A calculated field (getter) for the total monetary value of current stock
  get inventoryValue() {
    return this.sellingPrice * this.stockQuantity;
  }

  // Converts this class instance back into a plain JSON object (useful when sending data via API)
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      category: this.category,
      sellingPrice: this.sellingPrice,
      costPrice: this.costPrice,
      stockQuantity: this.stockQuantity,
      minimumStockLevel: this.minimumStockLevel,
      description: this.description,
      imageUrl: this.imageUrl,
      unit: this.unit,
      isLowStock: this.isLowStock, // Includes the calculated getter
      inventoryValue: this.inventoryValue, // Includes the calculated getter
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }
}

module.exports = Product;
