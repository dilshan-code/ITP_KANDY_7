import 'package:flutter/material.dart';
import 'package:frontend/features/suppliers/domain/entities/purchase.dart';
import 'package:frontend/features/suppliers/data/repositories/purchase_repository_impl.dart';

// PurchaseProvider handles the local state for all stock restocks from suppliers.
class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepositoryImpl _repository = PurchaseRepositoryImpl();

  List<Purchase> _purchases = []; // The list of purchase records to show in the UI
  bool _isLoading = false; // True if the app is currently talking to the server
  String? _error; // Stores error details if a search or save fails

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _purchases = await _repository.getAllPurchases();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Loads all purchases made specifically from one supplier.
  Future<void> fetchPurchasesBySupplier(String supplierId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _purchases = await _repository.getPurchasesBySupplier(supplierId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPurchase(Map<String, dynamic> data) async {
    try {
      await _repository.createPurchase(data);
      await fetchPurchases();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePurchase(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updatePurchase(id, data);
      await fetchPurchases();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePurchase(String id) async {
    try {
      await _repository.deletePurchase(id);
      await fetchPurchases();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
