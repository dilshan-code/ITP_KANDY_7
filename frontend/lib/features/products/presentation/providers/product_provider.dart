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
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  final int _pageSize = 20;

  // Public getters to allow UI to read the state
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Derived getter: returns only products that are critically low on stock
  List<Product> get lowStockProducts =>
      // Iterate through all products and 'where' filters in only those whose 'isLowStock' property is true
      _products.where((p) => p.isLowStock).toList();

  // Derived getter: calculates the total monetary value of all stock
  // Returns the grand total value of all items currently sitting in the shop.
  double get totalInventoryValue =>
      _products.fold(0.0, (sum, p) => sum + p.inventoryValue);
 
  // Calculates the sum of all individual items currently on the shelves.
  int get totalItemsInStock =>
      _products.fold(0, (sum, p) => sum + p.stockQuantity);
 
  // Identifies products that have reached or dropped below their 'minimumStockLevel'.
  // This is used for the 'Low Stock' alert badge on the dashboard.
  int get lowStockCount => _products.where((p) => p.isLowStock).length;
 
  // Returns a filtered list of products that need reordering.
  List<Product> get lowStockItems => _products.where((p) => p.isLowStock).toList();

  // Fetches the latest products from the backend with pagination support
  Future<void> fetchProducts({bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _hasMore = true;
      _error = null;
      notifyListeners();
    } else if (!_hasMore || _isFetchingMore) {
      return;
    } else {
      _isFetchingMore = true;
      notifyListeners();
    }

    try {
      final lastId = !refresh && _products.isNotEmpty ? _products.last.id : null;
      final fetchedProducts = await _repository.getAllProducts(
        limit: _pageSize,
        lastId: lastId,
      );

      if (refresh) {
        _products = fetchedProducts;
      } else {
        _products.addAll(fetchedProducts);
      }

      _hasMore = fetchedProducts.length == _pageSize;
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  // Private helper to upload an image file to the Cloudinary cloud storage.
  Future<String?> _uploadImage(File imageFile) async {
    // Check if Cloudinary configuration is available.
    if (CloudinaryConfig.cloudName.isEmpty ||
        CloudinaryConfig.uploadPreset.isEmpty) {
      debugPrint('Cloudinary config is missing. Skipping upload.');
      return null;
    }

    try {
      // Initialize the Cloudinary client with our API credentials.
      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false, // Disable caching for fresh uploads
      );

      // Upload the file as a 'product' resource to the 'products' folder.
      final CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'products',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Return the secure URL provided by Cloudinary to store in our database.
      return response.secureUrl;
    } catch (e) {
      debugPrint('❌ Cloudinary Upload Error: $e');
      _error = 'Image upload failed: $e'; // Set error message for UI
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
