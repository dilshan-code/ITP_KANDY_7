import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/shared/main_shell.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/core/utils/phone_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    // Demo data removed for brand new experience
    _phoneController.text = '+94';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_nameController.text.trim().isEmpty) {
      SnackBarUtils.showSnackBar(
        context,
        'Owner name is required',
        isError: true,
      );
      return;
    }
    if (_shopNameController.text.trim().isEmpty) {
      SnackBarUtils.showSnackBar(
        context,
        'Shop name is required',
        isError: true,
      );
      return;
    }
    final phone = normalizePhoneNumber(_phoneController.text.trim());
    if (phone.isEmpty || phone == '+94') {
      SnackBarUtils.showSnackBar(
        context,
        'Phone number is required',
        isError: true,
      );
      return;
    }
    if (_passwordController.text.trim().length < 8) {
      SnackBarUtils.showSnackBar(
        context,
        'Password must be at least 8 characters',
        isError: true,
      );
      return;
    }
    if (!_agreedToTerms) {
      SnackBarUtils.showSnackBar(
        context,
        'Please agree to the Terms of Service',
        isError: true,
      );
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register({
      'name': _nameController.text.trim(),
      'shopName': _shopNameController.text.trim(),
      'phone': phone,
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
    });

    if (!mounted) return;

    if (success) {
      SnackBarUtils.showSnackBar(
        context,
        'Account created successfully! Welcome to ClickBuy.',
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      SnackBarUtils.showSnackBar(
        context,
        authProvider.error ?? 'Registration failed. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Owner Registration'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Let's get started",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create an account to manage your grocery store',
                    style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Owner Name
                  _buildLabel('Owner Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Shop Name
                  _buildLabel('Shop Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your grocery store name',
                      prefixIcon: Icon(
                        Icons.store_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Phone Number
                  _buildLabel('Phone Number'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email
                  Row(
                    children: [
                      _buildLabel('Email'),
                      const SizedBox(width: 8),
                      Text(
                        'OPTIONAL',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email address (optional)',
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Create a strong password (min 8 characters)',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textLight,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textLight,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Terms & conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMedium,
                              ),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Error display
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.error != null) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            auth.error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Register button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2EE85C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Register Account',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppColors.textMedium),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textDark,
      ),
    );
  }
}
