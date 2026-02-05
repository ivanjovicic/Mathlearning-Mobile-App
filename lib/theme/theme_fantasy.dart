import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FantasyTheme {
  static ThemeData data = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5E6C8),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8B4513),
      secondary: Color(0xFFDAA520),
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.marcellus(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4B2E15),
      ),
      bodyLarge: GoogleFonts.lora(fontSize: 16, color: Color(0xFF4B2E15)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFF3DD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
