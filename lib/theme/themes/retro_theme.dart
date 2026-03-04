import 'package:flutter/material.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../core/theme_factory.dart';

class RetroTheme {
  RetroTheme._();

  static ThemeData dark() => buildTheme(
    colorScheme: _darkScheme,
    typographyConfig: TypographyConfig.retro,
    shapeProfile: ThemeShapeProfile.sharp,
  );

  static ThemeData light() => buildTheme(
    colorScheme: _lightScheme,
    typographyConfig: TypographyConfig.retro,
    shapeProfile: ThemeShapeProfile.sharp,
  );

  /// Dark is the canonical retro experience.
  static ThemeData get data => dark();

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFF00FF00),
    onPrimary: Colors.black,
    secondary: Color(0xFFFF00FF),
    onSecondary: Colors.black,
    tertiary: Color(0xFF00FFFF),
    onTertiary: Colors.black,
    surface: Color(0xFF181818),
    onSurface: Colors.white,
    error: Color(0xFFFF5555),
    onError: Colors.black,
  );

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFF007700),
    onPrimary: Colors.white,
    secondary: Color(0xFF770077),
    onSecondary: Colors.white,
    tertiary: Color(0xFF007777),
    onTertiary: Colors.white,
    surface: Color(0xFFDCDCDC),
    onSurface: Colors.black,
    error: Color(0xFFFF5555),
    onError: Colors.white,
  );
}
