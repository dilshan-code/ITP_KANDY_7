import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';

class AdminProvider extends ChangeNotifier {
  List<Owner> _owners = [];
  bool _isLoading = false;
  bool _isActionInProgress = false;
  String? _error;

  List<Owner> get owners => _owners;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
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
  int get pendingOwners =>
      _owners
          .where(
            (owner) => owner.status == 'pending' && owner.isSuspended == false,
          )
          .length;
  int get approvedOwners =>
      _owners
          .where(
            (owner) => owner.status == 'approved' && owner.isSuspended == false,
          )
          .length;
  int get suspendedOwners =>
      _owners
          .where(
            (owner) => owner.isSuspended || owner.status == 'suspended',
          )
          .length;

  Future<bool> _runOwnerAction(
    Future<Map<String, dynamic>> Function() request,
    String fallbackError,
  ) async {
    try {
      _isActionInProgress = true;
      _error = null;
      notifyListeners();

      final response = await request();
      if (response['success'] == true) {
        await fetchOwners();
        return true;
      }
      _error = response['error'] ?? fallbackError;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<bool> updateOwner(String id, Map<String, dynamic> data) async {
    return _runOwnerAction(
      () => ApiClient.put('/admin/owners/$id', data),
      'Failed to update owner',
    );
  }

  Future<bool> approveOwner(String id) async {
    return _runOwnerAction(
      () => ApiClient.put('/admin/owners/$id/approve', {}),
      'Failed to approve owner',
    );
  }

  Future<bool> suspendOwner(String id) async {
    return _runOwnerAction(
      () => ApiClient.put('/admin/owners/$id/suspend', {}),
      'Failed to suspend owner',
    );
  }

  Future<bool> moveOwnerToPending(String id) async {
    return _runOwnerAction(
      () => ApiClient.put('/admin/owners/$id', {
        'status': 'pending',
        'isSuspended': false,
      }),
      'Failed to move owner to pending',
    );
  }

  Future<bool> deleteOwner(String id) async {
    return _runOwnerAction(
      () => ApiClient.delete('/admin/owners/$id'),
      'Failed to delete owner',
    );
  }

  // Clear any existing errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
