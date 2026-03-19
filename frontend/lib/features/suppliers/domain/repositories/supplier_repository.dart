import 'package:frontend/features/suppliers/domain/entities/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getAllSuppliers();
  Future<Supplier?> getSupplierById(String id);
  Future<Supplier> createSupplier(Map<String, dynamic> data);
  Future<Supplier> updateSupplier(String id, Map<String, dynamic> data);
  Future<bool> deleteSupplier(String id);
}
