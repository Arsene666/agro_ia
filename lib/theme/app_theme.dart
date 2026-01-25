import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF2E7D32); // Forest Green
  static const Color secondaryGreen = Color(0xFF4CAF50); // Vibrant Green
  static const Color lightGreenBg = Color(0xFFF1F8E9); // Very light green for backgrounds
  
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greyText = Color(0xFF757575);
  static const Color white = Colors.white;

  // Alert Colors
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color warningOrange = Color(0xFFF57C00);
  static const Color warningBg = Color(0xFFFFF3E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: secondaryGreen,
        surface: const Color(0xFFFAFAFA), // Off-white background
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      
      // Typography
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: white,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkText,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: darkText,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: greyText,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        margin: EdgeInsets.zero,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor:  Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: white),
      ),
    );
  }
}
