import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';

class AdminProvider extends ChangeNotifier {
  List<Owner> _owners = [];
  bool _isLoading = false;
  String? _error;

  List<Owner> get owners => _owners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all store owners for the client dashboard
  Future<void> fetchOwners() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/admin/owners');
      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _owners = data.map((json) => Owner.fromJson(json)).toList();
      } else {
        _error = response['error'] ?? 'Failed to fetch owners';
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper for dashboard stats
  int get totalOwners => _owners.length;

  // Clear any existing errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
