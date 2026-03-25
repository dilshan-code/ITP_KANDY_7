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
  bool _isLoading = false;
  bool _isFetchingMoreTransactions = false;
  bool _hasMoreTransactions = true;
  bool _isFetchingMoreCustomers = false;
  bool _hasMoreCustomers = true;
  String? _error;
  static const int _pageSize = 20;

  List<Customer> get customers => _customers;
  List<CreditTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isFetchingMoreTransactions => _isFetchingMoreTransactions;
  bool get hasMoreTransactions => _hasMoreTransactions;
  bool get isFetchingMoreCustomers => _isFetchingMoreCustomers;
  bool get hasMoreCustomers => _hasMoreCustomers;
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
  Future<void> fetchCustomers({bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _hasMoreCustomers = true;
      _error = null;
      notifyListeners();
    } else if (!_hasMoreCustomers || _isFetchingMoreCustomers) {
      return;
    } else {
      _isFetchingMoreCustomers = true;
      notifyListeners();
    }

    try {
      final fetchedCustomers = await _repository.getAllCustomers(
        limit: _pageSize,
        lastId: refresh || _customers.isEmpty ? null : _customers.last.id,
      );

      if (refresh) {
        _customers = fetchedCustomers;
      } else {
        _customers.addAll(fetchedCustomers);
      }

      _hasMoreCustomers = fetchedCustomers.length == _pageSize;
      _isLoading = false;
      _isFetchingMoreCustomers = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isFetchingMoreCustomers = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions(String customerId, {bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _hasMoreTransactions = true;
      _error = null;
      notifyListeners();
    } else if (!_hasMoreTransactions || _isFetchingMoreTransactions) {
      return;
    } else {
      _isFetchingMoreTransactions = true;
      notifyListeners();
    }

    try {
      final fetchedTransactions = await _repository.getTransactionsByCustomer(
        customerId,
        limit: _pageSize,
        lastId: refresh || _transactions.isEmpty ? null : _transactions.last.id,
      );

      if (refresh) {
        _transactions = fetchedTransactions;
      } else {
        _transactions.addAll(fetchedTransactions);
      }

      _hasMoreTransactions = fetchedTransactions.length == _pageSize;
      _isLoading = false;
      _isFetchingMoreTransactions = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isFetchingMoreTransactions = false;
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
  // Now updated to create a Sale (Invoice) record for the settlement.
  Future<void> settleFullBalance(Customer customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Step 1: Fetch the ABSOLUTE latest customer data to ensure we have the correct balance.
      final latestCustomer = await _repository.getCustomerById(customer.id);
      if (latestCustomer == null || latestCustomer.totalOutstanding <= 0) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step 2: Create a Sale record with paymentMethod: 'settlement'
      // This will automatically update customer balance and create a credit transaction record in the backend.
      await _repository.createSettlementSale({
        'customerId': latestCustomer.id,
        'customerName': latestCustomer.name,
        'items': [], // Settlement invoice doesn't have product items
        'subtotal': latestCustomer.totalOutstanding,
        'totalAmount': latestCustomer.totalOutstanding,
        'paymentMethod': 'settlement',
      });

      // Step 3: Refresh local data
      await fetchCustomers();
      await fetchTransactions(latestCustomer.id);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
