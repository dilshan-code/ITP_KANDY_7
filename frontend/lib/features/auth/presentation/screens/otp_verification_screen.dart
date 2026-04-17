// ------------------------------------------------------------------------------
// File: otp_verification_screen.dart
// Purpose: Multi-Factor SMS Identity Validation.
// Rationale: Provides a secure verification gate using Firebase SMS 
//   handshakes. Ensures every shop owner is tethered to a verified physical 
//   device, implementing automated resend cooldowns and high-fidelity UX.
// ------------------------------------------------------------------------------
import 'dart:async'; // Utility: Timer system for resend logic
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:pinput/pinput.dart'; // Interaction: Specialized OTP input fields
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity manager
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart'; // Shared UI: Multi-layered background

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber; // Parameter: Target device identifier
  final VoidCallback onVerified; // Callback: Action to trigger on successful handshake

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // --- Input Orchestration ---
  final pinController = TextEditingController(); // Controller: Manages the 6-digit buffer
  final focusNode = FocusNode(); // Logic: Manages keyboard focus lifecycle
  final formKey = GlobalKey<FormState>(); // Key: Links PIN state to validation logic
  
  // --- Cooldown Orchestration ---
  Timer? _timer; // Instance: Active countdown timer
  int _secondsRemaining = 60; // State: Visual remaining seconds for resend lock

  @override
  void initState() {
    super.initState();
    _startTimer(); // Action: Initiate the first resend window immediately
  }

  /**
   * Logic: Synchronized Resend Countdown.
   * Rationale: Prevents SMS spam and API abuse by forcing a 60-second wait between resend attempts.
   */
  void _startTimer() {
    _timer?.cancel(); // Cleanup: Avoid overlapping timer ticks
    setState(() {
      _secondsRemaining = 60; // Reset: Standard industry-standard window
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel(); // Safety: Kill the background process if user navigates away
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--; // Decrement: Update UI tick
        } else {
          _timer?.cancel(); // Expired: Release the resend lock
        }
      });
    });
  }

  /**
   * Logic: Identity Resend Handshake.
   * Strategy: Re-initiates the Firebase Auth stream for the current session.
   */
  void _resendOtp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false); 
    
    await authProvider.resendOtp(
      phoneNumber: widget.phoneNumber,
      onVerificationFailed: (error) {
        if (!context.mounted) return;
        // Feedback: Show technical failure reason (e.g. rate limit reached).
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      },
      onCodeSent: () {
        if (!context.mounted) return;
        _startTimer(); // Restart: Apply a new 60s cooldown period
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
    _timer?.cancel(); // Cleanup: Memory safety for background loops
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const focusedBorderColor = AppColors.primary; // Aesthetic: Brand-aligned focus ring

    // --- Design System: Specialized PIN Boxes ---
    // Rationale: Large, accessible digit boxes for optimal thumb interaction.
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.poppins(
        fontSize: 22,
        color: AppColors.textDark,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
        color: Colors.black.withValues(alpha: 0.03), // Background: Subtle depth
      ),
    );

    return AuthBackground(
      showLogo: true, // Branding: Establish trust during the sensitive step
      child: Column(
        children: [
          // Header: Primary screen context.
          Text(
            'Verification',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Sub-header: Dynamic recipient confirmation.
          Text(
            'Enter the code sent to ${widget.phoneNumber}',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),
          
          // --- Verification Module ---
          GlassCard(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.phonelink_lock, // Icon: Symbolic security representation
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 32),
                  
                  // Interaction: Professional SMS entry block.
                  Pinput(
                    length: 6, // Strategy: Matches standard Firebase project settings
                    controller: pinController,
                    focusNode: focusNode,
                    defaultPinTheme: defaultPinTheme,
                    validator: (value) {
                      return value == null || value.length != 6 ? 'Enter full code' : null;
                    },
                    hapticFeedbackType: HapticFeedbackType.lightImpact, // Feedback: Tactile confirmation
                    onCompleted: (pin) async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      
                      // Logic: Trigger final Firebase code validation.
                      final success = await authProvider.verifyOtp(pin);
                      if (!context.mounted) return;

                      if (success) {
                        widget.onVerified(); // Action: Release the lock and proceed to home/success
                      } else {
                        pinController.clear(); // Safety: Wipe input on failure
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authProvider.error ?? 'Invalid OTP')),
                        );
                      }
                    },
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: focusedBorderColor, width: 2), // Active: Clear highlight
                      ),
                    ),
                    submittedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        color: Colors.black.withValues(alpha: 0.05), // Submitted: Visual feedback of processing
                        border: Border.all(color: focusedBorderColor),
                      ),
                    ),
                    errorPinTheme: defaultPinTheme.copyBorderWith(
                      border: Border.all(color: Colors.redAccent), // Error: Visual alert color
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // --- Resend Pipeline ---
                  // Rationale: Conditionally enables the retry mechanism based on the background timer.
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      if (auth.isLoading) {
                        return const CircularProgressIndicator(color: AppColors.primary);
                      }
                      return TextButton(
                        onPressed: _secondsRemaining == 0 ? _resendOtp : null, // Interaction: Disable until cooldown expires
                        child: Text(
                          _secondsRemaining > 0
                              ? 'Resend Code in ${_secondsRemaining}s' // Info: Clear expectation
                              : 'Resend Code', // CTA: Ready for retry
                          style: GoogleFonts.poppins(
                            color: _secondsRemaining > 0
                                ? AppColors.textLight
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}


