import 'package:flutter/material.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/services/phone_auth_service.dart';

// AuthProvider manages the sign-in state of the shop owner.
// It keeps track of who is logged in and handles login/registration actions.
class AuthProvider extends ChangeNotifier {
  final AuthRepositoryImpl _repository = AuthRepositoryImpl();
  final PhoneAuthService _phoneAuthService = PhoneAuthService();

  Owner? _currentOwner; // The profile details for the person currently using the app
  bool _isLoading = false; // True if we are waiting for the backend to respond
  String? _error; // Stores any error message if a login or register fails
  bool _isLoggedIn = false; // A simple flag to check if someone is signed in

  // Phone verification state
  String? _verificationId;
  int? _resendToken;

  Owner? get currentOwner => _currentOwner;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  String? get verificationId => _verificationId;

  /// Initiates the phone verification process via Firebase.
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String code) onVerificationCompleted,
    required Function(String error) onVerificationFailed,
    required VoidCallback onCodeSent,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _phoneAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
          notifyListeners();
          onCodeSent();
        },
        onVerificationFailed: (e) {
          _error = e.message ?? 'Verification failed';
          _isLoading = false;
          notifyListeners();
          onVerificationFailed(_error!);
        },
        onVerificationCompleted: (credential) async {
          // If auto-verification happens (e.g., on some Android devices)
          if (credential.smsCode != null) {
            onVerificationCompleted(credential.smsCode!);
          }
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      onVerificationFailed(_error!);
    }
  }

  /// Resends the OTP if requested by the user.
  Future<void> resendOtp({
    required String phoneNumber,
    required Function(String) onVerificationFailed,
    required VoidCallback onCodeSent,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _phoneAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onVerificationCompleted: (credential) async {
          _isLoading = false;
          notifyListeners();
        },
        onVerificationFailed: (e) {
          _isLoading = false;
          _error = e.message ?? 'Verification failed';
          notifyListeners();
          onVerificationFailed(_error!);
        },
        onCodeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _isLoading = false;
          notifyListeners();
          onCodeSent();
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          notifyListeners();
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      onVerificationFailed(_error!);
    }
  }

  Future<bool> verifyOtp(String smsCode) async {
    if (_verificationId == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _phoneAuthService.getCredential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      // We sign in with the credential to ensure it's valid.
      // This doesn't log the user into our custom backend yet.
      await _phoneAuthService.signInWithCredential(credential);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Invalid OTP code. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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

  Future<bool> resetPassword(String identifier, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.resetPassword(identifier, newPassword);
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
