import 'package:flutter/material.dart';

class AppColors {
  // Primary & Secondary
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFEFF6FF);
  
  // Backgrounds
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);
  
  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Semantic Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreen30 = Color(0x4D10B981);
  static const Color successGreenLight = Color(0xFFE5F8ED);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color warningOrangeLight = Color(0xFFFEF3C7);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPurpleLight = Color(0xFFF3E8FF);
  
  // Opacity pre-calculations (avoid withOpacity in builds)
  static const Color primaryBlue30 = Color(0x4D2563EB); // 30% alpha
  static const Color primaryBlue20 = Color(0x332563EB); // 20% alpha
  static const Color white80 = Color(0xCCFFFFFF); // 80% alpha
  static const Color black05 = Color(0x0D000000); // 5% alpha
  static const Color warningOrange30 = Color(0x4DF59E0B); // 30% alpha
  static const Color warningOrange10 = Color(0x1AF59E0B); // 10% alpha
  static const Color primaryBlue10 = Color(0x1A2563EB); // 10% alpha

  // Borders
  static const Color borderGrey = Color(0xFFE5E7EB);
}
