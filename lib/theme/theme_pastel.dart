import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PastelTheme {
  static ThemeData data = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF7F1),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF74C0FC),
      secondary: Color(0xFFFAA2C1),
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF444444),
      ),
      bodyLarge: GoogleFonts.quicksand(fontSize: 16, color: Color(0xFF555555)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
    ),
  );
}
