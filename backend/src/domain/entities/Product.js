// The Product entity represents a single item in the shop's inventory.
class Product {
  constructor({
    id,
    name,
    category,
    sellingPrice,
    purchasePrice,
    stockQuantity,
    minimumStockLevel,
    description,
    imageUrl,
    unit,
    notifyOutOfStock,
    createdAt,
    updatedAt,
  }) {
    this.id = id;
    this.name = name;
    this.category = category;
    this.sellingPrice = sellingPrice;
    this.purchasePrice = purchasePrice || 0;
    this.stockQuantity = stockQuantity;
    this.minimumStockLevel = minimumStockLevel;
    // Set default values if not provided
    this.description = description || '';
    this.imageUrl = imageUrl || '';
    this.unit = unit || 'ea';
    this.notifyOutOfStock = notifyOutOfStock !== undefined ? notifyOutOfStock : true;
    this.createdAt = createdAt || new Date().toISOString();
    this.updatedAt = updatedAt || new Date().toISOString();
  }

  // A calculated field (getter) that dynamically checks if stock is too low
  // Checks if we need to reorder this product soon because it's running out.
  get isLowStock() {
    return this.stockQuantity <= this.minimumStockLevel;
  }

  // A calculated field (getter) for the total monetary value of current stock
  // Calculates how much all the current stock of this product is worth to the business based on selling price.
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
      purchasePrice: this.purchasePrice,
      stockQuantity: this.stockQuantity,
      minimumStockLevel: this.minimumStockLevel,
      description: this.description,
      imageUrl: this.imageUrl,
      unit: this.unit,
      notifyOutOfStock: this.notifyOutOfStock,
      isLowStock: this.isLowStock, // Includes the calculated getter
      inventoryValue: this.inventoryValue,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }
}

module.exports = Product;
