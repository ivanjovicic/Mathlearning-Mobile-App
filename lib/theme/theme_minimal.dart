import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MinimalTheme {
  static ThemeData data = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.blueAccent,
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
    ),
    cardTheme: CardThemeData(
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
