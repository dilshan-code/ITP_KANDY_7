import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/products/domain/entities/product.dart';

// SaleProvider manages the shopping cart and finalises sales transactions.
// It also keeps track of the sales history shown in the app.
class SaleProvider extends ChangeNotifier {
  List<Product> _products = []; // Temporary list of products used for selecting items for a sale
  List<dynamic> _sales = []; // The history of completed sales
  final List<Map<String, dynamic>> _cartItems = []; // The items currently in the owner's "cart"
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<dynamic> get sales => _sales;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Calculates the sum price of all items currently in the cart.
  double get subtotal => _cartItems.fold(
    0,
    (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int),
  );
  double get totalAmount => subtotal;
  int get totalItems =>
      _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiClient.get('/products');
      _products = (response['data'] as List)
          .map((json) => Product.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiClient.get('/sales');
      _sales = (response['data'] as List).reversed.toList(); // Newest first
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adds a product to the cart or increases its quantity if already there.
  void addToCart(Product product) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item['productId'] == product.id,
    );
    if (existingIndex >= 0) {
      final currentQty = _cartItems[existingIndex]['quantity'] as int;
      if (currentQty < product.stockQuantity) {
        _cartItems[existingIndex]['quantity'] = currentQty + 1;
      } else {
        throw Exception('Stock limit reached for ${product.name}');
      }
    } else {
      if (product.stockQuantity > 0) {
        _cartItems.add({
          'productId': product.id,
          'name': product.name,
          'price': product.sellingPrice,
          'quantity': 1,
          'unit': product.unit,
          'stockQuantity': product.stockQuantity, // Store for local validation
        });
      } else {
        throw Exception('${product.name} is out of stock');
      }
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _cartItems.removeAt(index);
    } else {
      final item = _cartItems[index];
      final stockPerItem = item['stockQuantity'] as int;
      if (quantity <= stockPerItem) {
        _cartItems[index]['quantity'] = quantity;
      }
    }
    notifyListeners();
  }

  // Sends the cart data to the backend to create a permanent sale record.
  Future<Map<String, dynamic>?> completeSale({
    String? id, // Optional pre-generated ID
    String paymentMethod = 'cash',
    String customerId = '',
    String customerName = '',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await ApiClient.post('/sales', {
        'id': id,
        'items': _cartItems,
        'subtotal': subtotal,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'customerId': customerId,
        'customerName': customerName,
      });
      _cartItems.clear();
      _isLoading = false;

      // Auto-refresh sales history when a new sale is completed
      fetchSales();

      notifyListeners();
      return response['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteSale(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await ApiClient.delete('/sales/$id');
      await fetchSales();
      await fetchProducts(); // Refresh products to show reverted stock
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
