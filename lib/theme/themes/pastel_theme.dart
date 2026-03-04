import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../core/theme_factory.dart';

class PastelTheme {
  PastelTheme._();

  static ThemeData light() => buildTheme(
    colorScheme: _lightScheme,
    typographyConfig: TypographyConfig.quicksand,
    shapeProfile: ThemeShapeProfile.soft,
  );

  static ThemeData dark() => buildTheme(
    colorScheme: _darkScheme,
    typographyConfig: TypographyConfig.quicksand,
    shapeProfile: ThemeShapeProfile.soft,
  );

  /// Convenience getter for ThemeController compatibility.
  static ThemeData get data => light();

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFF74C0FC),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFD0E8FF),
    onPrimaryContainer: Color(0xFF00274D),
    secondary: Color(0xFFFAA2C1),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFD9E5),
    onSecondaryContainer: Color(0xFF4A001F),
    surface: Color(0xFFFFF7F1),
    onSurface: Color(0xFF4E342E),
    surfaceContainerHighest: Color(0xFFFFF3E0),
    onSurfaceVariant: Color(0xFF4E342E),
  );

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFF5A9BD8),
    onPrimary: Color(0xFF00274D),
    primaryContainer: Color(0xFF003A6B),
    onPrimaryContainer: Color(0xFFD0E8FF),
    secondary: Color(0xFFDB6E8F),
    onSecondary: Color(0xFF4A001F),
    secondaryContainer: Color(0xFF7A2C47),
    onSecondaryContainer: Color(0xFFFFD9E5),
    surface: Color(0xFF2E1E1A),
    onSurface: Color(0xFFFFEDE5),
    surfaceContainerHighest: Color(0xFF3E2E2A),
    onSurfaceVariant: Color(0xFFFFEDE5),
  );
}
