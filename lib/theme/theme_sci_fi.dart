import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SciFiPalette {
  // Dark mode colors
  static const Color deepSpace = Color(0xFF050816);
  static const Color panelSurface = Color(0xFF111827);
  static const Color neonPurple = Color(0xFF6C63FF);
  static const Color neonAmber = Color(0xFFFFB800);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color glitchPink = Color(0xFFFF4EDB);
  static const Color dangerRed = Color(0xFFFF3B3B);
  static const Color successGreen = Color(0xFF00FFB2);

  // Light mode colors
  static const Color cleanInterface = Color(0xFFF5F5F5);
  static const Color lightPanel = Color(0xFFE0E0E0);
  static const Color softPurple = Color(0xFFB39DFF);
  static const Color softAmber = Color(0xFFFFD54F);
  static const Color softCyan = Color(0xFF80DEEA);
}

class SciFiTheme {
  static ThemeData dark() {
    final colorScheme = _buildDarkColorScheme();
    return _buildTheme(colorScheme);
  }

  static ThemeData light() {
    final colorScheme = _buildLightColorScheme();
    return _buildTheme(colorScheme);
  }

  static ColorScheme _buildDarkColorScheme() {
    return const ColorScheme.dark(
      primary: SciFiPalette.neonPurple,
      secondary: SciFiPalette.neonAmber,
      tertiary: SciFiPalette.neonCyan,
      surface: SciFiPalette.panelSurface,
      error: SciFiPalette.dangerRed,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.black,
    );
  }

  static ColorScheme _buildLightColorScheme() {
    return const ColorScheme.light(
      primary: SciFiPalette.softPurple,
      secondary: SciFiPalette.softAmber,
      tertiary: SciFiPalette.softCyan,
      surface: SciFiPalette.lightPanel,
      error: SciFiPalette.dangerRed,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(colorScheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
      dividerTheme: _buildDividerTheme(colorScheme),
      tooltipTheme: _buildTooltipTheme(colorScheme),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.orbitron(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: colorScheme.primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
      labelLarge: GoogleFonts.rajdhani(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: colorScheme.secondary,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 2,
      titleTextStyle: GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      color: colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(colorScheme.primary),
        foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(colorScheme.primary),
        side: WidgetStateProperty.all(
          BorderSide(color: colorScheme.primary, width: 2),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(colorScheme.primary),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    );
  }

  static DialogThemeData _buildDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  static DividerThemeData _buildDividerTheme(ColorScheme colorScheme) {
    return DividerThemeData(
      color: colorScheme.outline,
      thickness: 1,
    );
  }

  static TooltipThemeData _buildTooltipTheme(ColorScheme colorScheme) {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(color: colorScheme.onSurface),
    );
  }
  // Backwards-compatible getter used by ThemeController
  static ThemeData get data => light();
}
