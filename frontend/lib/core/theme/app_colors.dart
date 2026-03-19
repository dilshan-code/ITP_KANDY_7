import 'package:flutter/material.dart';

// AppColors stores all the hardcoded color values used throughout the UI.
// Using this central file makes it incredibly easy to change the app's 'theme'
// (like updating the primary green color) by just editing it here once.
class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF029934);
  static const Color primaryDark = Color(0xFF017A29);
  
  // Backgrounds
  static const Color background = Color(0xFFF5F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMedium = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  
  // Utility and status colors
  static const Color divider = Color(0xFFF3F4F6);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  
  // Specific UI component colors
  static const Color cardGreenBg = Color(0xFFD1FAE5);
  static const Color cardRedBg = Color(0xFFFEE2E2);
  static const Color cardOrangeBg = Color(0xFFFEF3C7);
  static const Color cardBlueBg = Color(0xFFDBEAFE);
  static const Color accentGreen = Color(0xFFD1FAE5);
}
