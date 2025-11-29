import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const primary = Color(0xFF6366F1); // Indigo
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);
  
  // Secondary colors
  static const secondary = Color(0xFF8B5CF6); // Purple
  static const secondaryDark = Color(0xFF7C3AED);
  static const secondaryLight = Color(0xFFA78BFA);
  
  // Accent colors
  static const accent = Color(0xFF06B6D4); // Cyan
  static const success = Color(0xFF10B981); // Green
  static const warning = Color(0xFFF59E0B); // Amber
  static const error = Color(0xFFEF4444); // Red
  static const info = Color(0xFF3B82F6); // Blue
  
  // Neutral colors
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF3F4F6);
  
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textDisabled = Color(0xFFD1D5DB);
  
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF3F4F6);
  
  static const divider = Color(0xFFE5E7EB);
  
  // Status colors
  static const online = Color(0xFF10B981);
  static const offline = Color(0xFF6B7280);
  static const away = Color(0xFFF59E0B);
  static const busy = Color(0xFFEF4444);
  
  // Gradient
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );
  
  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, primary],
  );
}
