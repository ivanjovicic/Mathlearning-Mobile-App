import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PastelPalette {
  // Light mode colors
  static const Color primaryLight = Color(0xFF74C0FC);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color primaryContainerLight = Color(0xFFD0E8FF);
  static const Color onPrimaryContainerLight = Color(0xFF00274D);

  static const Color secondaryLight = Color(0xFFFAA2C1);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryContainerLight = Color(0xFFFFD9E5);
  static const Color onSecondaryContainerLight = Color(0xFF4A001F);

  static const Color backgroundLight = Color(0xFFFFF7F1);
  static const Color onBackgroundLight = Color(0xFF4E342E);
  static const Color surfaceLight = Color(0xFFFFF3E0);
  static const Color onSurfaceLight = Color(0xFF4E342E);

  // Dark mode colors
  static const Color primaryDark = Color(0xFF5A9BD8);
  static const Color onPrimaryDark = Color(0xFF00274D);
  static const Color primaryContainerDark = Color(0xFF003A6B);
  static const Color onPrimaryContainerDark = Color(0xFFD0E8FF);

  static const Color secondaryDark = Color(0xFFDB6E8F);
  static const Color onSecondaryDark = Color(0xFF4A001F);
  static const Color secondaryContainerDark = Color(0xFF7A2C47);
  static const Color onSecondaryContainerDark = Color(0xFFFFD9E5);

  static const Color backgroundDark = Color(0xFF2E1E1A);
  static const Color onBackgroundDark = Color(0xFFFFEDE5);
  static const Color surfaceDark = Color(0xFF3E2E2A);
  static const Color onSurfaceDark = Color(0xFFFFEDE5);

  // Semantic colors
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFD54F);
  static const Color error = Color(0xFFE57373);
  static const Color info = Color(0xFF64B5F6);
}

class PastelTheme {
  static ThemeData light() {
    final colorScheme = _buildLightColorScheme();
    return _buildTheme(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme = _buildDarkColorScheme();
    return _buildTheme(colorScheme);
  }

  static ColorScheme _buildLightColorScheme() {
    return const ColorScheme.light(
      primary: PastelPalette.primaryLight,
      onPrimary: PastelPalette.onPrimaryLight,
      primaryContainer: PastelPalette.primaryContainerLight,
      onPrimaryContainer: PastelPalette.onPrimaryContainerLight,
      secondary: PastelPalette.secondaryLight,
      onSecondary: PastelPalette.onSecondaryLight,
      secondaryContainer: PastelPalette.secondaryContainerLight,
      onSecondaryContainer: PastelPalette.onSecondaryContainerLight,
      surface: PastelPalette.backgroundLight,
      onSurface: PastelPalette.onBackgroundLight,
      surfaceContainerHighest: PastelPalette.surfaceLight,
      onSurfaceVariant: PastelPalette.onSurfaceLight,
    );
  }

  static ColorScheme _buildDarkColorScheme() {
    return const ColorScheme.dark(
      primary: PastelPalette.primaryDark,
      onPrimary: PastelPalette.onPrimaryDark,
      primaryContainer: PastelPalette.primaryContainerDark,
      onPrimaryContainer: PastelPalette.onPrimaryContainerDark,
      secondary: PastelPalette.secondaryDark,
      onSecondary: PastelPalette.onSecondaryDark,
      secondaryContainer: PastelPalette.secondaryContainerDark,
      onSecondaryContainer: PastelPalette.onSecondaryContainerDark,
      surface: PastelPalette.backgroundDark,
      onSurface: PastelPalette.onBackgroundDark,
      surfaceContainerHighest: PastelPalette.surfaceDark,
      onSurfaceVariant: PastelPalette.onSurfaceDark,
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
      displayLarge: GoogleFonts.quicksand(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: GoogleFonts.quicksand(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.quicksand(
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
      labelLarge: GoogleFonts.quicksand(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.primaryContainer,
      elevation: 2,
      titleTextStyle: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      color: colorScheme.surfaceContainerHighest,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.surfaceContainerHighest;
          }
          return colorScheme.primary;
        }),
        foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
          BorderSide(color: colorScheme.primary),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: colorScheme.outline),
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
      backgroundColor: colorScheme.surfaceContainerHighest,
      titleTextStyle: GoogleFonts.quicksand(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      contentTextStyle: GoogleFonts.quicksand(
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // Backwards-compatible getter used by ThemeController
  static ThemeData get data => light();

  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
}
