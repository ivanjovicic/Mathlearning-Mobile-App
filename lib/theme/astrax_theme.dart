import 'package:flutter/material.dart';

class AstraXTheme {
  // Brand colors
  static const Color neonBlue = Color(0xFF59C7FF);
  static const Color neonPurple = Color(0xFFB06BFF);
  static const Color neonGreen = Color(0xFF52FFB3);

  // Const compatibility values used in const contexts by legacy UI
  static const Color panel = Color(0xFF1D1E24);
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Backwards-compatible convenience colors used across screens
  static Color get bg => const Color(0xFF0C0D10);
  static Color get panelLight => const Color(0xFF1D1E24);
  static Color get danger => const Color(0xFFFF6B6B);

  static ThemeData buildDarkTheme() {
    final colorScheme = ColorScheme.dark(
      primary: neonBlue,
      onPrimary: Color(0xFF001E30),
      primaryContainer: Color(0xFF1A3A50),
      onPrimaryContainer: Color(0xFFCBE6FF),
      secondary: neonPurple,
      onSecondary: Color(0xFF1B0040),
      secondaryContainer: Color(0xFF2E1A5C),
      onSecondaryContainer: Color(0xFFE1D0FF),
      tertiary: neonGreen,
      onTertiary: Color(0xFF003822),
      tertiaryContainer: Color(0xFF0A4D33),
      onTertiaryContainer: Color(0xFFB3FFD9),
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
      background: Color(0xFF0C0D10),
      onBackground: Color(0xFFF0F2F5),
      surface: Color(0xFF14151A),
      onSurface: Color(0xFFF0F2F5),
      surfaceVariant: Color(0xFF1D1E24),
      onSurfaceVariant: Color(0xFF9CA3AF),
      outline: Color(0xFF3A3B44),
      outlineVariant: Color(0xFF2A2B33),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      // CardTheme vs CardThemeData compatibility: accept either and map
      // cardTheme omitted for SDK compatibility; rely on defaults
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onSecondaryContainer;
          }
          return colorScheme.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.secondaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.surfaceContainerHighest;
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurfaceVariant;
            }
            return colorScheme.onPrimary;
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
