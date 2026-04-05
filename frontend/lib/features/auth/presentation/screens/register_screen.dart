import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/utils/snackbar_utils.dart';
import 'package:frontend/shared/main_shell.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/core/utils/phone_utils.dart';
import 'package:frontend/core/utils/validation_utils.dart';
import 'package:frontend/features/auth/presentation/screens/otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      SnackBarUtils.showSnackBar(
        context,
        'Please agree to the Terms of Service',
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = normalizePhoneNumber(_phoneController.text.trim());

    // Step 1: Send OTP via Firebase
    await authProvider.sendOtp(
      phoneNumber: phone,
      onVerificationCompleted: (code) {
        // Auto-verification handled if supported
      },
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
                // Step 3: Proceed with backend registration after OTP is verified
                final success = await authProvider.register({
                  'name': _nameController.text.trim(),
                  'shopName': _shopNameController.text.trim(),
                  'phone': phone,
                  'email': _emailController.text.trim(),
                  'password': _passwordController.text.trim(),
                });

                if (!context.mounted) return;

                if (success) {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Account created successfully! Welcome to ClickBuy.',
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Owner Registration'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Owner Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: AppColors.textLight,
                          ),
                        ),
                        validator: (v) => ValidationUtils.validateRequired(v, 'Owner name'),
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Shop Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your grocery store name',
                          prefixIcon: Icon(
                            Icons.store_outlined,
                            color: AppColors.textLight,
                          ),
                        ),
                        validator: (v) => ValidationUtils.validateRequired(v, 'Shop name'),
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Phone Number'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter your phone number',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: AppColors.textLight,
                          ),
                        ),
                        validator: ValidationUtils.validatePhone,
                      ),
                      const SizedBox(height: 20),

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
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email address (optional)',
                          prefixIcon: Icon(
                            Icons.mail_outline,
                            color: AppColors.textLight,
                          ),
                        ),
                        validator: ValidationUtils.validateEmail,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      TextFormField(
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
                        validator: ValidationUtils.validatePassword,
                      ),
                      const SizedBox(height: 20),

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
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

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
              ),
            ],
          ),
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
