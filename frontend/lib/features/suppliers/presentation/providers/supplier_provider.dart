import 'package:flutter/material.dart';
import 'package:frontend/features/suppliers/domain/entities/supplier.dart';
import 'package:frontend/features/suppliers/data/repositories/supplier_repository_impl.dart';

// SupplierProvider manages the list of business partners who supply products to the shop.
class SupplierProvider extends ChangeNotifier {
  final SupplierRepositoryImpl _repository = SupplierRepositoryImpl();

  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  final int _pageSize = 20;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  int get activeCount => _suppliers.where((s) => s.status == 'active').length;
  double get totalPayable =>
      _suppliers.fold(0, (sum, s) => sum + s.totalPayable);

  Future<void> fetchSuppliers({bool refresh = true}) async {
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
      final fetchedSuppliers = await _repository.getAllSuppliers(
        limit: _pageSize,
        lastId: refresh || _suppliers.isEmpty ? null : _suppliers.last.id,
      );

      if (refresh) {
        _suppliers = fetchedSuppliers;
      } else {
        _suppliers.addAll(fetchedSuppliers);
      }

      _hasMore = fetchedSuppliers.length == _pageSize;
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

  Future<bool> addSupplier(Map<String, dynamic> data) async {
    try {
      await _repository.createSupplier(data);
      await fetchSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplier(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateSupplier(id, data);
      await fetchSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeSupplier(String id) async {
    try {
      await _repository.deleteSupplier(id);
      await fetchSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
