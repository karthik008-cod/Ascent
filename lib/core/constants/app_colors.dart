import 'package:flutter/material.dart';

class AppColors {
  // ── Dark Mode ──
  static const Color background = Color(0xFF09090B); // Deep OLED Black
  static const Color surface = Color(0xFF18181B); // Slightly lighter for cards
  static const Color surfaceHighlight = Color(0xFF27272A);
  
  static const Color primary = Color(0xFF8B5CF6); // Deep Purple
  static const Color primaryVariant = Color(0xFF6D28D9); 
  static const Color secondary = Color(0xFF3B82F6); // Electric Blue
  static const Color accent = Color(0xFFF59E0B); // Sunset orange for highlights
  
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Gradient for special elements
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Light Mode ──
  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHighlight = Color(0xFFE4E4E7);

  static const Color lightTextPrimary = Color(0xFF18181B);
  static const Color lightTextSecondary = Color(0xFF71717A);
}
