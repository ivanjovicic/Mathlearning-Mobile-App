import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RetroPalette {
  // Dark mode colors
  static const Color backgroundDark = Color(0xFF101010);
  static const Color surfaceDark = Color(0xFF181818);
  static const Color primaryDark = Color(0xFF00FF00);
  static const Color secondaryDark = Color(0xFFFF00FF);
  static const Color tertiaryDark = Color(0xFF00FFFF);

  static const Color success = Color(0xFF5CFF5C);
  static const Color warning = Color(0xFFFFD800);
  static const Color error = Color(0xFFFF5555);
  static const Color info = Color(0xFF57C7FF);

  // Light mode colors (optional)
  static const Color backgroundLight = Color(0xFFEFEFEF);
  static const Color surfaceLight = Color(0xFFDCDCDC);
  static const Color primaryLight = Color(0xFF007700);
  static const Color secondaryLight = Color(0xFF770077);
  static const Color tertiaryLight = Color(0xFF007777);
}

class RetroTheme {
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
      primary: RetroPalette.primaryDark,
      secondary: RetroPalette.secondaryDark,
      tertiary: RetroPalette.tertiaryDark,
      background: RetroPalette.backgroundDark,
      surface: RetroPalette.surfaceDark,
      error: RetroPalette.error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white,
      onError: Colors.black,
    );
  }

  static ColorScheme _buildLightColorScheme() {
    return const ColorScheme.light(
      primary: RetroPalette.primaryLight,
      secondary: RetroPalette.secondaryLight,
      tertiary: RetroPalette.tertiaryLight,
      background: RetroPalette.backgroundLight,
      surface: RetroPalette.surfaceLight,
      error: RetroPalette.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
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
      displaySmall: GoogleFonts.pressStart2p(
        fontSize: 20,
        color: colorScheme.onBackground,
      ),
      headlineMedium: GoogleFonts.pressStart2p(
        fontSize: 16,
        color: colorScheme.primary,
      ),
      bodyLarge: GoogleFonts.shareTechMono(
        fontSize: 14,
        color: colorScheme.onSurface,
      ),
      labelLarge: GoogleFonts.pressStart2p(
        fontSize: 12,
        color: colorScheme.secondary,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      backgroundColor: colorScheme.surface,
      elevation: 2,
      titleTextStyle: GoogleFonts.pressStart2p(
        fontSize: 16,
        color: colorScheme.primary,
      ),
    );
  }

  static CardTheme _buildCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      color: colorScheme.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(colorScheme.primary),
        foregroundColor: MaterialStateProperty.all(colorScheme.onPrimary),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(colorScheme.primary),
        side: MaterialStateProperty.all(
          BorderSide(color: colorScheme.primary, width: 2),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all(colorScheme.primary),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
    );
  }

  static DialogTheme _buildDialogTheme(ColorScheme colorScheme) {
    return DialogTheme(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
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
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: TextStyle(color: colorScheme.onSurface),
    );
  }
  // Backwards-compatible getter used by ThemeController
  static ThemeData get data => light();
}
