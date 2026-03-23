import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/credit/domain/entities/customer.dart';
import 'package:frontend/features/credit/domain/entities/credit_transaction.dart';

// CreditRepositoryImpl handles all data tasks related to customers and their credit history.
class CreditRepositoryImpl {
  // Customer methods
  // Lists all customers in the system by fetching them from the backend.
  Future<List<Customer>> getAllCustomers() async {
    final response = await ApiClient.get('/customers');
    return (response['data'] as List)
        .map((json) => Customer.fromJson(json))
        .toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final response = await ApiClient.get('/customers/$id');
    return Customer.fromJson(response['data']);
  }

  // Adds a new customer profile to the database.
  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/customers', data);
    return Customer.fromJson(response['data']);
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/customers/$id', data);
    return Customer.fromJson(response['data']);
  }

  Future<bool> deleteCustomer(String id) async {
    final response = await ApiClient.delete('/customers/$id');
    return response['success'] == true;
  }

  // Credit Transaction methods
  // Fetches a list of all credit-related transactions (debt/payments) for a customer.
  Future<List<CreditTransaction>> getTransactionsByCustomer(
    String customerId,
  ) async {
    final response = await ApiClient.get(
      '/credit-transactions/customer/$customerId',
    );
    return (response['data'] as List)
        .map((json) => CreditTransaction.fromJson(json))
        .toList();
  }

  // Records a new credit or payment transaction for a customer.
  Future<CreditTransaction> createTransaction(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/credit-transactions', data);
    return CreditTransaction.fromJson(response['data']);
  }

  // Sales methods (for credit history)
  // Removed getSalesByCustomer as we now use SaleProvider directly.
}
