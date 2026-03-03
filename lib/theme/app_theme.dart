import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData buildDarkGamifiedTheme({bool highContrast = false}) {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C63FF),
      brightness: Brightness.dark,
    );

    final colorScheme = highContrast
      ? baseColorScheme.copyWith(
        primary: baseColorScheme.primary,
        onPrimary: baseColorScheme.onPrimary,
        primaryContainer: baseColorScheme.primaryContainer,
        onPrimaryContainer: baseColorScheme.onPrimaryContainer,
        secondary: baseColorScheme.secondary,
        onSecondary: baseColorScheme.onSecondary,
        secondaryContainer: baseColorScheme.secondaryContainer,
        onSecondaryContainer: baseColorScheme.onSecondaryContainer,
        surface: baseColorScheme.surface,
        onSurface: baseColorScheme.onSurface,
        surfaceContainerHighest: baseColorScheme.surfaceVariant,
        onSurfaceVariant: baseColorScheme.onSurfaceVariant,
        error: baseColorScheme.error,
        onError: baseColorScheme.onError,
        outline: baseColorScheme.outline,
        )
        : baseColorScheme;

    final textTheme = GoogleFonts.interTextTheme(
      Typography.material2021().white,
    ).apply(
      displayColor: colorScheme.onSurface,
      bodyColor: colorScheme.onSurface,
    ).copyWith(
      displayLarge: GoogleFonts.orbitron(
        fontSize: 57,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.orbitron(
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.primary,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                ? colorScheme.onSurface.withValues(alpha: 0.12)
                : colorScheme.primary),
            foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                ? colorScheme.onSurface.withValues(alpha: 0.38)
                : colorScheme.onPrimary),
            shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            elevation: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.pressed) ? 1 : 3),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        elevation: 6,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
