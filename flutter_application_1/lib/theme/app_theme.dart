import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand & Primary
  static const Color primaryNavy = Color(0xFF0F2C59);
  static const Color primaryBlue = Color(0xFF1D58D8);
  static const Color primaryLight = Color(0xFFEBF1FD);

  // Backgrounds & Surface
  static const Color background = Color(0xFFF3F6FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEEF2F6);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Accents
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFE6F8F0);
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF5E7);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEECEB);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEBF3FE);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleBg = Color(0xFFF3EDFD);
}

class AppTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.promptTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryNavy,
        surface: AppColors.surface,
      ),
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.prompt(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }
}

