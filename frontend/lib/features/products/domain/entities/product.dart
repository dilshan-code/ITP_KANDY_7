// This is the core data model for a Product in the Flutter app.
// It defines the properties of a product and how to convert it to/from JSON.
class Product {
  final String id;
  final String name;
  final String category;
  final double sellingPrice;
  final double costPrice;
  final int stockQuantity;
  final int minimumStockLevel;
  final String description;
  final String imageUrl;
  final String unit;
  final bool isLowStock; // Received from backend calculation
  final double inventoryValue; // Received from backend calculation

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    required this.costPrice,
    required this.stockQuantity,
    required this.minimumStockLevel,
    this.description = '',
    this.imageUrl = '',
    this.unit = 'ea',
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
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      stockQuantity: (json['stockQuantity'] ?? 0).toInt(),
      minimumStockLevel: (json['minimumStockLevel'] ?? 0).toInt(),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      unit: json['unit'] ?? 'ea',
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
      'costPrice': costPrice,
      'stockQuantity': stockQuantity,
      'minimumStockLevel': minimumStockLevel,
      'description': description,
      'imageUrl': imageUrl,
      'unit': unit,
    };
  }

  // Helper method used by UI to show an indicator bar of stock health
  double get stockPercentage {
    if (minimumStockLevel == 0) return 1.0;
    // Assuming 5x the min stock level is considered "full capacity" for gauge UI
    final maxStock = minimumStockLevel * 5;
    return (stockQuantity / maxStock).clamp(0.0, 1.0);
  }
}
