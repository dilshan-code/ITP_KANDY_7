import 'package:flutter/material.dart';
import 'package:frontend/features/credit/domain/entities/customer.dart';
import 'package:frontend/features/credit/domain/entities/credit_transaction.dart';
import 'package:frontend/features/credit/data/repositories/credit_repository_impl.dart';

// CreditProvider manages the list of customers and their credit (debt) history.
// It notifies the UI to update whenever a payment is made or a new customer is added.
class CreditProvider extends ChangeNotifier {
  final CreditRepositoryImpl _repository = CreditRepositoryImpl();

  List<Customer> _customers = []; // The complete list of shop customers
  List<CreditTransaction> _transactions = []; // History of debts and payments for a selected customer
  List<Map<String, dynamic>> _customerSales = []; // List of sales linked to a specific customer
  bool _isLoading = false; // Flag to show a progress spinner during network calls
  String? _error; // Holds any error message from the backend

  List<Customer> get customers => _customers;
  List<CreditTransaction> get transactions => _transactions;
  List<Map<String, dynamic>> get customerSales => _customerSales;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalOutstanding =>
      _customers.fold(0, (sum, c) => sum + c.totalOutstanding);
  int get activeCredits =>
      _customers.where((c) => c.totalOutstanding > 0).length;

  List<Customer> get outstandingCustomers =>
      _customers.where((c) => c.totalOutstanding > 0).toList();
  List<Customer> get settledCustomers =>
      _customers.where((c) => c.totalOutstanding <= 0).toList();

  // Fetches all customers from the backend database.
  Future<void> fetchCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _customers = await _repository.getAllCustomers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions(String customerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _transactions = await _repository.getTransactionsByCustomer(customerId);
      _customerSales = await _repository.getSalesByCustomer(customerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCustomer(Map<String, dynamic> data) async {
    try {
      await _repository.createCustomer(data);
      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateCustomer(id, data);
      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      final success = await _repository.deleteCustomer(id);
      if (success) {
        await fetchCustomers();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTransaction(Map<String, dynamic> data) async {
    try {
      await _repository.createTransaction(data);
      // After adding a transaction, refresh the customer data too as their balance changed
      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // A helper method that records a payment for the entire outstanding debt of a customer.
  Future<void> settleFullBalance(Customer customer) async {
    if (customer.totalOutstanding <= 0) return;

    _isLoading = true;
    notifyListeners();
    try {
      await _repository.createTransaction({
        'customerId': customer.id,
        'type': 'payment',
        'title': 'Full Balance Settlement',
        'amount': customer.totalOutstanding,
      });
      await fetchCustomers();
      await fetchTransactions(customer.id);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
