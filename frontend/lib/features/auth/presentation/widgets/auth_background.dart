// ------------------------------------------------------------------------------
// File: auth_background.dart
// Purpose: Branded Visual Foundation for Authentication Screens.
// Rationale: Implements a high-fidelity glassmorphic background system with 
//   dynamic mesh gradients and adaptive layout containers. Ensures visual 
//   continuity across all identity-related screens.
// ------------------------------------------------------------------------------
import 'dart:ui'; // UI: Rendering primitives and blur filters
import 'package:flutter/material.dart'; // Core: Flutter UI framework
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens

class AuthBackground extends StatelessWidget {
  final Widget child;
  final bool showLogo;
  final Widget? leading;
  final Widget? trailing;

  const AuthBackground({
    super.key,
    required this.child,
    this.showLogo = true,
    this.leading,
    this.trailing,
  });

  @override
    Widget build(BuildContext context) {
    // Root container ensures the base color covers any gaps or orientation/size transitions.
    return Container(
      color: const Color(0xFFF0FDF4), // Fresh Emerald-50 base 
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let the background container show through
        resizeToAvoidBottomInset: false, // Prevents layout shifting when keyboard appears
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Mesh Gradient Blobs: Create an organic, premium design feel
            Positioned(
              top: -100,
              right: -100,
              child: _Blob(
                color: AppColors.primary.withValues(alpha: 0.18), // Soft primary glow
                size: 500,
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: _Blob(
                color: const Color(0xFF93C5FD).withValues(alpha: 0.15), // Subtle blue accent
                size: 450,
              ),
            ),
            Positioned(
              top: 150,
              left: -100,
              child: _Blob(
                color: AppColors.accentGreen.withValues(alpha: 0.22), // Secondary green highlight
                size: 300,
              ),
            ),

            // Glassmorphism Blur Layer: Blends blobs into a smooth, frosted background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), // Heavy blur for "mesh" effect
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Main Content Layer: Centered scrollable area for auth forms
            Positioned.fill(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(), // High bounce feel
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight, // Ensure center alignment even for short screens
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showLogo) ...[
                                  const _AuthLogo(), // Central branding component
                                  const SizedBox(height: 24),
                                ],
                                // Specialized auth content (Login, Register, etc.)
                                child,
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Floating Actions Layer: Handles top-level navigation and settings
            if (leading != null || trailing != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (leading != null) leading! else const SizedBox(width: 48), // e.g. Back button
                        if (trailing != null) trailing! else const SizedBox(width: 48), // e.g. Settings button
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Internal primitive for drawing colored background shapes
class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Shared branding component for consistent auth entry points
class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: const Icon(
            Icons.storefront_rounded, // Use shop icon for "Owner" portal identity
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ClickBuy', // Brand voice
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }
}

// Specialized reusable container for high-fidelity "Glass" effects
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Local blur for the card content
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6), // Rich frosted translucent look
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), // Edge highlight for glass realism
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), // Subtle depth lift
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
    );
  }
}

