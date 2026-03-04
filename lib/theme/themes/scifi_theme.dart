import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../core/theme_factory.dart';

class SciFiTheme {
  SciFiTheme._();

  static ThemeData dark() => buildTheme(
    colorScheme: _darkScheme,
    typographyConfig: TypographyConfig.sciFi,
    shapeProfile: ThemeShapeProfile.rounded,
  );

  static ThemeData light() => buildTheme(
    colorScheme: _lightScheme,
    typographyConfig: TypographyConfig.sciFi,
    shapeProfile: ThemeShapeProfile.rounded,
  );

  /// Dark is the canonical sci-fi experience.
  static ThemeData get data => dark();

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFF6C63FF),
    onPrimary: Colors.white,
    secondary: Color(0xFFFFB800),
    onSecondary: Colors.black,
    tertiary: Color(0xFF00E5FF),
    onTertiary: Colors.black,
    surface: Color(0xFF111827),
    onSurface: Colors.white,
    error: Color(0xFFFF3B3B),
    onError: Colors.black,
  );

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFFB39DFF),
    onPrimary: Colors.black,
    secondary: Color(0xFFFFD54F),
    onSecondary: Colors.black,
    tertiary: Color(0xFF80DEEA),
    onTertiary: Colors.black,
    surface: Color(0xFFE0E0E0),
    onSurface: Colors.black,
    error: Color(0xFFFF3B3B),
    onError: Colors.white,
  );
}
