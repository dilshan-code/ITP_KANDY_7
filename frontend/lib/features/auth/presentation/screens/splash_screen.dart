// ------------------------------------------------------------------------------
// File: splash_screen.dart
// Purpose: Application Entry and Foundational Bootstrap.
// Rationale: Orchestrates the application's initial visual handover and 
//   environmental setup. Provides brand recognition via animations while 
//   silently initializing backend discovery and local session state.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Brand color palette
import 'package:frontend/features/auth/presentation/screens/login_screen.dart'; // Navigation: Primary exit route
import 'package:frontend/features/auth/presentation/screens/get_started_screen.dart'; // Navigation: First-run onboarding route
import 'package:shared_preferences/shared_preferences.dart'; // Logic: Local persistent flag storage
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart'; // Shared UI: Branded background wrapper
import 'package:frontend/core/network/backend_discovery.dart'; // Logic: UDP server heartbeat scanner
import 'package:flutter/foundation.dart'; // Utility: Environment checks (kIsWeb)

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // --- Animation Orchestration ---
  late AnimationController _controller; // Logic: Drives the timeline of the entrance effect
  late Animation<double> _fadeAnimation; // Smoothness: Linear opacity increase
  late Animation<double> _scaleAnimation; // Impact: Elastic bounce effect for and logo pop

  @override
  void initState() {
    super.initState();
    
    // Initializer: Set a 1.5s duration for the total branding sequence.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade: Moves from invisible (0.0) to solid (1.0).
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // Scale: Uses an ElasticOut curve to create a "Bounce" sensation.
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward(); // Activation: Trigger animations immediately on mount.
    _navigateToNext(); // Sequence: Trigger background logic concurrently with visuals.
  }

  /**
   * Logic: Entry-Route Decision Tree.
   * Rationale: Determines if the user is a newcomer (shos GetStarted) or a returning owner (show Login).
   * Also ensures the backend IP is discovered before the user starts interacting.
   */
  Future<void> _navigateToNext() async {
    final prefs = await SharedPreferences.getInstance(); // Protocol: Access internal storage
    final bool hasSeenGetStarted = prefs.getBool('has_seen_get_started') ?? false; // Check: Binary onboarding flag

    // Synchronization: Wait for BOTH minimum branding time (2s) AND the UDP heartbeat (if applicable).
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2000)), // Minimum: Prevent jarring immediate transitions
      // Network: Discover local laptop IP automatically on mobile networks.
      if (!kIsWeb) BackendDiscovery.waitForDiscovery(timeout: const Duration(seconds: 6)),
    ]);

    if (!mounted) return; // Guard: Prevent navigation if the widget was unmounted fast

    // Outcome: Forward the user to the appropriate security context.
    if (!hasSeenGetStarted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Cleanup: Memory safety for the ticker
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showLogo: false, // Override: Uses the custom, animated logo columns defined below
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation, // Animation: Primary Fade
          child: ScaleTransition(
            scale: _scaleAnimation, // Animation: Logo Bounce
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branded Container: Geometric shield for the logo icon.
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_bag_rounded,
                      size: 72,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Heading: Main Product Identity.
                Text(
                  'ClickBuy',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -1,
                  ),
                ),
                // Subline: Functional Identity.
                Text(
                  'PREMIUM STORE MANAGER',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 48),
                // Progress: Subtle indicator that background discovery/boot-up is active.
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


