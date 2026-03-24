import 'package:frontend/features/products/domain/entities/product.dart';

// This interface defines the contract for interacting with product data
// on the frontend. The actual implementation (ProductRepositoryImpl)
// handles the real API calls. This separation makes testing easier.
abstract class ProductRepository {
  Future<List<Product>> getAllProducts();
  Future<Product?> getProductById(String id);
  Future<Product> createProduct(Map<String, dynamic> data);
  Future<Product> updateProduct(String id, Map<String, dynamic> data);
  Future<bool> deleteProduct(String id);
}
