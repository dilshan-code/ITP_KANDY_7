import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/suppliers/domain/entities/supplier.dart';
import 'package:frontend/features/suppliers/domain/repositories/supplier_repository.dart';

// SupplierRepositoryImpl manages the communication with the backend regarding product suppliers.
class SupplierRepositoryImpl implements SupplierRepository {
  // Retrieves every supplier from the server's database.
  @override
  Future<List<Supplier>> getAllSuppliers() async {
    final response = await ApiClient.get('/suppliers');
    return (response['data'] as List)
        .map((json) => Supplier.fromJson(json))
        .toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    final response = await ApiClient.get('/suppliers/$id');
    return Supplier.fromJson(response['data']);
  }

  // Registers a new business partner as a supplier.
  @override
  Future<Supplier> createSupplier(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/suppliers', data);
    return Supplier.fromJson(response['data']);
  }

  @override
  Future<Supplier> updateSupplier(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/suppliers/$id', data);
    return Supplier.fromJson(response['data']);
  }

  // Deletes a supplier record from the system.
  @override
  Future<bool> deleteSupplier(String id) async {
    await ApiClient.delete('/suppliers/$id');
    return true;
  }
}
