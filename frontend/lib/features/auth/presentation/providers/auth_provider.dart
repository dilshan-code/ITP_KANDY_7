import 'package:flutter/material.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/core/network/api_client.dart';

// AuthProvider manages the sign-in state of the shop owner.
// It keeps track of who is logged in and handles login/registration actions.
class AuthProvider extends ChangeNotifier {
  final AuthRepositoryImpl _repository = AuthRepositoryImpl();

  Owner? _currentOwner; // The profile details for the person currently using the app
  bool _isLoading = false; // True if we are waiting for the backend to respond
  String? _error; // Stores any error message if a login or register fails
  bool _isLoggedIn = false; // A simple flag to check if someone is signed in

  Owner? get currentOwner => _currentOwner;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;

  // Tells the app to log in a user with their email/phone and password.
  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentOwner = await _repository.login(identifier, password);
      // Set the global ownerId for API calls
      if (_currentOwner != null) {
        ApiClient.ownerId = _currentOwner!.id;
      }
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentOwner = await _repository.register(data);
      // Set the global ownerId for API calls
      if (_currentOwner != null) {
        ApiClient.ownerId = _currentOwner!.id;
      }
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logs the user out and clears their profile from the app's memory.
  void logout() {
    _currentOwner = null;
    _isLoggedIn = false;
    // Clear the global ownerId
    ApiClient.ownerId = null;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_currentOwner == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentOwner = await _repository.updateProfile(_currentOwner!.id, data);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentOwner == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.changePassword(
        _currentOwner!.id,
        oldPassword,
        newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
