import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

class SnackBarUtils {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Clear existing snackbars to avoid stacking
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isError
            ? AppColors.error.withValues(alpha: 0.95)
            : AppColors.primary.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.only(
          bottom: 72, // Positioned above the bottom navigation bar
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
  }
}
