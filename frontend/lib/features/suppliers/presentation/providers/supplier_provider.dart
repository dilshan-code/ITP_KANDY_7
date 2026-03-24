import 'package:flutter/material.dart';
import 'package:frontend/features/suppliers/domain/entities/supplier.dart';
import 'package:frontend/features/suppliers/data/repositories/supplier_repository_impl.dart';

// SupplierProvider manages the list of business partners who supply products to the shop.
class SupplierProvider extends ChangeNotifier {
  final SupplierRepositoryImpl _repository = SupplierRepositoryImpl();

  List<Supplier> _suppliers = []; // All registered suppliers
  bool _isLoading = false; // Indicates if data is currently being downloaded
  String? _error; // Background error details if a request fails

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeCount => _suppliers.where((s) => s.status == 'active').length;
  double get totalPayable =>
      _suppliers.fold(0, (sum, s) => sum + s.totalPayable);

  // Refreshes the list of suppliers by pulling the latest data from the server.
  Future<void> fetchSuppliers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _suppliers = await _repository.getAllSuppliers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
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
