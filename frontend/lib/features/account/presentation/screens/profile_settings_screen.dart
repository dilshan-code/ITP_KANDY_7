import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/core/utils/phone_utils.dart';
import 'package:frontend/core/utils/validation_utils.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shopNameController;
  late TextEditingController _phoneController;

  final _passwordFormKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final owner = context.read<AuthProvider>().currentOwner;
    _nameController = TextEditingController(text: owner?.name);
    _shopNameController = TextEditingController(text: owner?.shopName);
    _phoneController = TextEditingController(text: owner?.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().updateProfile({
      'name': _nameController.text,
      'shopName': _shopNameController.text,
      'phone': normalizePhoneNumber(_phoneController.text),
    });

    if (mounted) {
      if (success) {
        SnackBarUtils.showSnackBar(context, 'Profile updated successfully');
      } else {
        SnackBarUtils.showSnackBar(
          context,
          context.read<AuthProvider>().error ?? 'Failed to update profile',
          isError: true,
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (mounted) {
      if (success) {
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        SnackBarUtils.showSnackBar(context, 'Password changed successfully');
      } else {
        SnackBarUtils.showSnackBar(
          context,
          context.read<AuthProvider>().error ?? 'Failed to change password',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSection(
              title: 'PERSONAL INFORMATION',
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      icon: Icons.person_outline,
                      label: 'Name',
                      child: TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Enter your name'),
                        validator: (v) => ValidationUtils.validateRequired(v, 'Name'),
                      ),
                    ),
                    _buildSettingsItem(
                      icon: Icons.store_outlined,
                      label: 'Shop Name',
                      child: TextFormField(
                        controller: _shopNameController,
                        decoration: _inputDecoration('Enter shop name'),
                        validator: (v) => ValidationUtils.validateRequired(v, 'Shop name'),
                      ),
                    ),
                    _buildSettingsItem(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration('Enter phone'),
                        validator: ValidationUtils.validatePhone,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: context.watch<AuthProvider>().isLoading
                              ? null
                              : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: context.watch<AuthProvider>().isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Profile Details',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: 'SECURITY',
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      icon: Icons.lock_outline,
                      label: 'Current Password',
                      child: TextFormField(
                        controller: _oldPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration('Enter current password'),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ),
                    _buildSettingsItem(
                      icon: Icons.lock_reset_outlined,
                      label: 'New Password',
                      child: TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration('Min. 8 characters'),
                        validator: ValidationUtils.validatePassword,
                      ),
                    ),
                    _buildSettingsItem(
                      icon: Icons.lock_reset_outlined,
                      label: 'Confirm Password',
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration('Re-enter new password'),
                        validator: (val) {
                          if (val != _newPasswordController.text) {
                            return 'No match';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: context.watch<AuthProvider>().isLoading
                              ? null
                              : _changePassword,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Update Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
