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

  // Adds a product to the temporary shopping cart before finalizing the sale.
  void addToCart(Product product) {
    // Step 1: Check if this item is already in the cart using its unique ID.
    final existingIndex = _cartItems.indexWhere(
      (item) => item['productId'] == product.id,
    );

    if (existingIndex >= 0) {
      // Step 2: If it IS in the cart, check if adding one more exceeds available stock.
      final currentQty = _cartItems[existingIndex]['quantity'] as int;
      if (currentQty < product.stockQuantity) {
        // Increment the quantity for the existing item.
        _cartItems[existingIndex]['quantity'] = currentQty + 1;
      } else {
        // Throw an error if the user tries to sell more than they have.
        throw Exception('Stock limit reached for ${product.name}');
      }
    } else {
      // Step 3: If it's a NEW item, ensure there is at least one in stock.
      if (product.stockQuantity > 0) {
        // Add a new Map representing the line item with necessary product details.
        _cartItems.add({
          'productId': product.id,
          'name': product.name,
          'price': product.sellingPrice,
          'quantity': 1,
          'unit': product.unit,
          'stockQuantity': product.stockQuantity, // Keep for local limit checks.
        });
      } else {
        throw Exception('${product.name} is out of stock');
      }
    }
    // Step 4: Tell the UI to refresh to show the updated cart state.
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

  // Sends the finalized cart data to the backend to record a sale and update inventory.
  Future<Map<String, dynamic>?> completeSale({
    String? id,
    String paymentMethod = 'cash',
    String customerId = '',
    String customerName = '',
  }) async {
    try {
      // Step 1: Show a loading spinner in the UI.
      _isLoading = true;
      notifyListeners();

      // Step 2: Execute the network POST request to /sales with the cart contents.
      final response = await ApiClient.post('/sales', {
        'id': id,
        'items': _cartItems,
        'subtotal': subtotal,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'customerId': customerId,
        'customerName': customerName,
      });

      // Step 3: Clear the local cart now that the sale is recorded in the database.
      _cartItems.clear();
      _isLoading = false;

      // Step 4: Refresh local history so the user sees the new sale immediately.
      fetchSales();
      fetchProducts(); // Refresh products to show updated stock counts.

      notifyListeners();
      // Return the recorded sale data back to the UI.
      return response['data'] as Map<String, dynamic>?;
    } catch (e) {
      // If the API call fails, capture the error and stop the loading spinner.
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
