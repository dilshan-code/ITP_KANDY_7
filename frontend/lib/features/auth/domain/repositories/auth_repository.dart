import 'package:frontend/features/auth/domain/entities/owner.dart';

abstract class AuthRepository {
  Future<Owner> login(String email, String password);
  Future<Owner> register(Map<String, dynamic> data);
  Future<Owner?> getProfile(String id);
  Future<Owner> updateProfile(String id, Map<String, dynamic> data);
  Future<void> changePassword(
    String id,
    String oldPassword,
    String newPassword,
  );
}
