import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SciFiTheme {
  static ThemeData data = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF050816),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFFFFB800),
      surface: Color(0xFF111827),
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF111827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
