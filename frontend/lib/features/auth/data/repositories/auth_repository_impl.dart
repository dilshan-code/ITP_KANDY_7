import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

// AuthRepositoryImpl is responsible for talking to the backend about user accounts.
// It handles login, registration, and profile updates by using the ApiClient.
class AuthRepositoryImpl implements AuthRepository {
  // Attempts to log in a user and returns their profile details if successful.
  @override
  Future<Owner> login(String identifier, String password) async {
    final response = await ApiClient.post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });
    return Owner.fromJson(response['data']);
  }

  // Creates a new owner account in the system.
  @override
  Future<Owner> register(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/auth/register', data);
    return Owner.fromJson(response['data']);
  }

  // Fetches the current user's profile information.
  @override
  Future<Owner?> getProfile(String id) async {
    final response = await ApiClient.get('/auth/profile/$id');
    return Owner.fromJson(response['data']);
  }

  // Saves modifications to a user's profile (name, shop name, etc.).
  @override
  Future<Owner> updateProfile(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/auth/profile/$id', data);
    return Owner.fromJson(response['data']);
  }

  @override
  Future<void> changePassword(
    String id,
    String oldPassword,
    String newPassword,
  ) async {
    await ApiClient.put('/auth/change-password/$id', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> resetPassword(String identifier, String newPassword) async {
    await ApiClient.post('/auth/reset-password', {
      'identifier': identifier,
      'newPassword': newPassword,
    });
  }
}
