import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../core/theme_factory.dart';

class FantasyTheme {
  FantasyTheme._();

  static ThemeData light() => buildTheme(
    colorScheme: _lightScheme,
    typographyConfig: TypographyConfig.fantasy,
    shapeProfile: ThemeShapeProfile.rounded,
  );

  static ThemeData dark() => buildTheme(
    colorScheme: _darkScheme,
    typographyConfig: TypographyConfig.fantasy,
    shapeProfile: ThemeShapeProfile.rounded,
  );

  static ThemeData get data => light();

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFF8B4513),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD7B899),
    onPrimaryContainer: Color(0xFF4B2E15),
    secondary: Color(0xFFDAA520),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF5E6C8),
    onSecondaryContainer: Color(0xFF4B2E15),
    tertiary: Color(0xFF228B22),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFB5E3B5),
    onTertiaryContainer: Color(0xFF003300),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFF3DD),
    onSurface: Color(0xFF4B2E15),
    surfaceContainerHighest: Color(0xFFEFE2C8),
    onSurfaceVariant: Color(0xFF6B4E2E),
    outline: Color(0xFF8B6A4E),
    outlineVariant: Color(0xFFD7B899),
    surfaceContainerLow: Color(0xFFFDF4E3),
    surfaceContainer: Color(0xFFFBEED9),
    surfaceContainerHigh: Color(0xFFF8E6C8),
  );

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFFD4956A),
    onPrimary: Color(0xFF2A0E00),
    primaryContainer: Color(0xFF6A3010),
    onPrimaryContainer: Color(0xFFFFDBC8),
    secondary: Color(0xFFE8C96A),
    onSecondary: Color(0xFF2B1D00),
    surface: Color(0xFF1C1208),
    onSurface: Color(0xFFEEDFCB),
    outline: Color(0xFF80603A),
    outlineVariant: Color(0xFF4D3820),
  );
}
