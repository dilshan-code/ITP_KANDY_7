import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:frontend/core/utils/phone_utils.dart';
import 'package:frontend/core/utils/validation_utils.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      SnackBarUtils.showSnackBar(
        context,
        'Passwords do not match',
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _identifierController.text.trim();
    
    // Normalize phone number if it's not an email
    String phone;
    if (identifier.contains('@')) {
      SnackBarUtils.showSnackBar(
        context,
        'Please enter your registered phone number for verification.',
        isError: true,
      );
      return;
    } else {
      phone = normalizePhoneNumber(identifier);
    }

    // Step 1: Send OTP via Firebase
    await authProvider.sendOtp(
      phoneNumber: phone,
      onVerificationCompleted: (code) {},
      onVerificationFailed: (error) {
        SnackBarUtils.showSnackBar(context, error, isError: true);
      },
      onCodeSent: () {
        // Step 2: Navigate to OTP Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              phoneNumber: phone,
              onVerified: () async {
                // Step 3: Proceed with backend reset after OTP is verified
                final success = await authProvider.resetPassword(
                  phone,
                  _passwordController.text.trim(),
                );

                if (!context.mounted) return;

                if (success) {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Password reset successfully! Please login with your new password.',
                  );
                  // Pop both OTP and Reset screens to return to Login
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.lock_reset,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Create New Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Enter your registered email or phone and your new password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Identifier field
                    const Text(
                      'Email or Phone',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Registered email or phone',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: ValidationUtils.validateIdentifier,
                    ),
                    const SizedBox(height: 20),

                    // New Password field
                    const Text(
                      'New Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Minimum 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: ValidationUtils.validatePassword,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password field
                    const Text(
                      'Confirm New Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        hintText: 'Re-enter new password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Reset Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _resetPassword,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: auth.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Confirm Reset',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
