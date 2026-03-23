import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:frontend/core/config/cloudinary_config.dart';
import 'package:frontend/features/products/domain/entities/product.dart';
import 'package:frontend/features/products/data/repositories/product_repository_impl.dart';

// ProductProvider manages the state of the products in the app.
// It notifies the UI to rebuild whenever data changes (using notifyListeners()).
class ProductProvider extends ChangeNotifier {
  final ProductRepositoryImpl _repository = ProductRepositoryImpl();

  // Internal state variables
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  // Public getters to allow UI to read the state
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Derived getter: returns only products that are critically low on stock
  List<Product> get lowStockProducts =>
      // Iterate through all products and 'where' filters in only those whose 'isLowStock' property is true
      _products.where((p) => p.isLowStock).toList();

  // Derived getter: calculates the total monetary value of all stock
  double get totalInventoryValue =>
      // fold(initialValue, function) acts like reduce; sums up the 'inventoryValue' of every product
      _products.fold(0.0, (sum, p) => sum + p.inventoryValue);

  // Derived getter: calculates the total number of items currently in stock
  int get totalItemsInStock =>
      // sums up the raw 'stockQuantity' integer for all products
      _products.fold(0, (sum, p) => sum + p.stockQuantity);

  // Fetches the latest products from the backend
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Tells the UI to show a loading spinner

    try {
      _products = await _repository.getAllProducts();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners(); // Tells the UI to hide the spinner and show data
  }

  // Helper: Upload file to Cloudinary and return the secure URL
  Future<String?> _uploadImage(File imageFile) async {
    if (CloudinaryConfig.cloudName.isEmpty ||
        CloudinaryConfig.uploadPreset.isEmpty) {
      debugPrint('Cloudinary config is missing. Skipping upload.');
      return null;
    }

    try {
      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false,
      );

      final CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'products',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      _error = 'Image upload failed: $e';
      return null;
    }
  }

  // Creates a new product, saves it via backend, and refreshes the list
  Future<bool> createProduct(Map<String, dynamic> data, {File? imageFile}) async {
    try {
      if (imageFile != null) {
        final url = await _uploadImage(imageFile);
        if (url != null) {
          data['imageUrl'] = url;
        }
      }
      await _repository.createProduct(data);
      await fetchProducts(); // Refresh list to include the new product
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Updates an existing product, saves it via backend, and refreshes the list
  Future<bool> updateProduct(String id, Map<String, dynamic> data, {File? imageFile}) async {
    try {
      if (imageFile != null) {
        final url = await _uploadImage(imageFile);
        if (url != null) {
          data['imageUrl'] = url;
        }
      }
      await _repository.updateProduct(id, data);
      await fetchProducts(); // Refresh list to reflect updates
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Deletes a product, saves the deletion via backend, and refreshes the list
  Future<bool> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await fetchProducts(); // Refresh list to remove the deleted product
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
