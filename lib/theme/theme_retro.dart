import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RetroTheme {
  static ThemeData data = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00FF00),
      secondary: Color(0xFFFF00FF),
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.pressStart2p(
        fontSize: 16,
        color: Color(0xFF00FF00),
      ),
      bodyLarge: GoogleFonts.pressStart2p(
        fontSize: 13,
        color: Color(0xFFB0FFB0),
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF222222),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF00FF00), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
