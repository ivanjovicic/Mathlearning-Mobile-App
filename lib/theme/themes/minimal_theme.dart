import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../core/theme_factory.dart';

class MinimalTheme {
  MinimalTheme._();

  static ThemeData light() => buildTheme(
    colorScheme: _lightScheme,
    typographyConfig: TypographyConfig.quicksand,
    shapeProfile: ThemeShapeProfile.clean,
  );

  static ThemeData dark() => buildTheme(
    colorScheme: _darkScheme,
    typographyConfig: TypographyConfig.quicksand,
    shapeProfile: ThemeShapeProfile.clean,
  );

  static ThemeData get data => light();

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFFB3E5FC),
    onPrimary: Color(0xFF004D40),
    primaryContainer: Color(0xFFE1F5FE),
    onPrimaryContainer: Color(0xFF006064),
    secondary: Color(0xFFFFCDD2),
    onSecondary: Color(0xFFB71C1C),
    secondaryContainer: Color(0xFFFFEBEE),
    onSecondaryContainer: Color(0xFF880E4F),
    tertiary: Color(0xFFD1C4E9),
    onTertiary: Color(0xFF311B92),
    tertiaryContainer: Color(0xFFEDE7F6),
    onTertiaryContainer: Color(0xFF512DA8),
    error: Color(0xFFB00020),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFF3E0),
    onSurface: Color(0xFF4E342E),
    surfaceContainerHighest: Color(0xFFECEFF1),
    onSurfaceVariant: Color(0xFF37474F),
    outline: Color(0xFFB0BEC5),
    outlineVariant: Color(0xFFCFD8DC),
    surfaceContainerLow: Color(0xFFFFF9E6),
    surfaceContainer: Color(0xFFFFF5DC),
    surfaceContainerHigh: Color(0xFFFFF1D3),
  );

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFF81D4FA),
    onPrimary: Color(0xFF01579B),
    primaryContainer: Color(0xFF0277BD),
    onPrimaryContainer: Color(0xFFB3E5FC),
    secondary: Color(0xFFEF9A9A),
    onSecondary: Color(0xFF7F0000),
    surface: Color(0xFF1A1A2E),
    onSurface: Color(0xFFE0E0E0),
    outline: Color(0xFF546E7A),
    outlineVariant: Color(0xFF37474F),
  );
}
