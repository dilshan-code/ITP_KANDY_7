// The Product entity represents a single item available in the shop's inventory.
class Product {
  final String id;
  final String name;
  final String category;
  final double sellingPrice;
  final int stockQuantity;
  final int minimumStockLevel;
  final String description;
  final String imageUrl;
  final String unit;
  final bool notifyOutOfStock;
  final bool isLowStock; // Received from backend calculation
  final double inventoryValue; // Received from backend calculation

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.minimumStockLevel,
    this.description = '',
    this.imageUrl = '',
    this.unit = 'ea',
    this.notifyOutOfStock = true,
    this.isLowStock = false,
    this.inventoryValue = 0,
  });

  // A "factory constructor" builds a new Product from a JSON object (a Map).
  // This is used when receiving data from the backend API.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      // Ensure prices are parsed as doubles, even if the backend sends an integer
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      stockQuantity: (json['stockQuantity'] ?? 0).toInt(),
      minimumStockLevel: (json['minimumStockLevel'] ?? 0).toInt(),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      unit: json['unit'] ?? 'ea',
      notifyOutOfStock: json['notifyOutOfStock'] ?? true,
      isLowStock: json['isLowStock'] ?? false,
      inventoryValue: (json['inventoryValue'] ?? 0).toDouble(),
    );
  }

  // Converts the Product instance into a JSON object (a Map).
  // This is used when sending data to the backend API.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'minimumStockLevel': minimumStockLevel,
      'description': description,
      'imageUrl': imageUrl,
      'unit': unit,
      'notifyOutOfStock': notifyOutOfStock,
    };
  }

  // Helper method used by UI to show an indicator bar of stock health
  // Returns a percentage (0.0 to 1.0) of how much stock we have relative to our needs.
  // Useful for showing a visual progress bar or gauge in the UI.
  double get stockPercentage {
    if (minimumStockLevel == 0) return 1.0;
    // Assuming 5x the min stock level is considered "full capacity" for gauge UI
    final maxStock = minimumStockLevel * 5;
    return (stockQuantity / maxStock).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
