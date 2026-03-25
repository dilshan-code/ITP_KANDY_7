import 'package:flutter/material.dart';
import 'package:frontend/features/suppliers/domain/entities/purchase.dart';
import 'package:frontend/features/suppliers/data/repositories/purchase_repository_impl.dart';

// PurchaseProvider handles the local state for all stock restocks from suppliers.
class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepositoryImpl _repository = PurchaseRepositoryImpl();

  List<Purchase> _purchases = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  final int _pageSize = 20;

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> fetchPurchases({bool refresh = true}) async {
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
      final lastId = !refresh && _purchases.isNotEmpty ? _purchases.last.id : null;
      final fetchedPurchases = await _repository.getAllPurchases(
        limit: _pageSize,
        lastId: lastId,
      );

      if (refresh) {
        _purchases = fetchedPurchases;
      } else {
        _purchases.addAll(fetchedPurchases);
      }

      _hasMore = fetchedPurchases.length == _pageSize;
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

  Future<void> fetchPurchasesBySupplier(String supplierId, {bool refresh = true}) async {
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
      final lastId = !refresh && _purchases.isNotEmpty ? _purchases.last.id : null;
      final fetchedPurchases = await _repository.getPurchasesBySupplier(
        supplierId,
        limit: _pageSize,
        lastId: lastId,
      );

      if (refresh) {
        _purchases = fetchedPurchases;
      } else {
        _purchases.addAll(fetchedPurchases);
      }

      _hasMore = fetchedPurchases.length == _pageSize;
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
