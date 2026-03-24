import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/products/domain/entities/product.dart';
import 'package:frontend/features/products/domain/repositories/product_repository.dart';

// This is the concrete implementation of the ProductRepository interface.
// It uses ApiClient to send requests to the Node.js backend.
class ProductRepositoryImpl implements ProductRepository {
  // Fetches all products from the backend and converts JSON data into Product objects
  @override
  Future<List<Product>> getAllProducts() async {
    // Call the network helper to fire a GET /products to the Node server
    final response = await ApiClient.get('/products');
    // Extract the raw array from the 'data' key returned by Node
    final List data = response['data'];
    // Map over each raw JSON object and construct a strongly typed Dart Product model, then return as a List
    return data.map((json) => Product.fromJson(json)).toList();
  }

  // Fetches a single product by ID
  @override
  Future<Product?> getProductById(String id) async {
    final response = await ApiClient.get('/products/$id');
    return Product.fromJson(response['data']);
  }

  // Sends new product data to the backend to be created in Firestore
  @override
  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/products', data);
    return Product.fromJson(response['data']);
  }

  // Sends updated data for an existing product to the backend
  @override
  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/products/$id', data);
    return Product.fromJson(response['data']);
  }

  // Tells the backend to delete a product by ID
  @override
  Future<bool> deleteProduct(String id) async {
    final response = await ApiClient.delete('/products/$id');
    return response['success'] ?? false;
  }
}
