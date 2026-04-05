import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}
class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final pinController = TextEditingController();
  final focusNode = FocusNode();
  final formKey = GlobalKey<FormState>();
  Timer? _timer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _resendOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.resendOtp(
      phoneNumber: widget.phoneNumber,
      onVerificationFailed: (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      },
      onCodeSent: () {
        if (!context.mounted) return;
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent!'),
            backgroundColor: AppColors.primary,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = AppColors.primary;
    const fillColor = Color.fromRGBO(243, 246, 249, 0);
    const borderColor = Color.fromRGBO(23, 171, 144, 0.4);

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phonelink_lock,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We have sent a 6-digit code to\n${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(height: 48),
                Pinput(
                  length: 6,
                  controller: pinController,
                  focusNode: focusNode,
                  defaultPinTheme: defaultPinTheme,
                  validator: (value) {
                    return value == null || value.length != 6 ? 'Enter full code' : null;
                  },
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                  onCompleted: (pin) async {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final success = await authProvider.verifyOtp(pin);
                    if (!context.mounted) return;

                    if (success) {
                      widget.onVerified();
                    } else {
                      pinController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authProvider.error ?? 'Invalid OTP')),
                      );
                    }
                  },
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: focusedBorderColor),
                    ),
                  ),
                  submittedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: focusedBorderColor),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyBorderWith(
                    border: Border.all(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 48),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.isLoading) {
                      return const CircularProgressIndicator();
                    }
                    return TextButton(
                      onPressed: _secondsRemaining == 0 ? _resendOtp : null,
                      child: Text(
                        _secondsRemaining > 0
                            ? 'Resend Code in ${_secondsRemaining}s'
                            : 'Resend Code',
                        style: TextStyle(
                          color: _secondsRemaining > 0
                              ? AppColors.textMedium
                              : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
