import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import '../core/theme_factory.dart';

/// Astra theme — futuristic neon aesthetic using the centralized factory.
class AstraTheme {
  AstraTheme._();

  /// Default Astra typography — Orbitron for display, Inter for body.
  static final _typography = TypographyConfig(
    displayBuilder: (b) => GoogleFonts.orbitron(
      textStyle: b.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2),
    ),
    headlineBuilder: (b) => GoogleFonts.orbitron(
      textStyle: b.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.0),
    ),
    bodyBuilder: (b) => GoogleFonts.inter(textStyle: b),
    labelBuilder: (b) => GoogleFonts.inter(
      textStyle: b.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  static ThemeData dark() => buildTheme(
    colorScheme: _darkScheme,
    typographyConfig: _typography,
    shapeProfile: ThemeShapeProfile.neon,
  );

  static ThemeData light() => buildTheme(
    colorScheme: _lightScheme,
    typographyConfig: _typography,
    shapeProfile: ThemeShapeProfile.neon,
  );

  /// Dark is the canonical Astra experience.
  static ThemeData get data => dark();

  // ── Brand convenience getters (for legacy widgets) ─────────────────────
  static const Color neonBlue = Color(0xFF59C7FF);
  static const Color neonPurple = Color(0xFFB06BFF);
  static const Color neonGreen = Color(0xFF52FFB3);

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: Color(0xFF59C7FF),
    onPrimary: Color(0xFF001E30),
    primaryContainer: Color(0xFF1A3A50),
    onPrimaryContainer: Color(0xFFCBE6FF),
    secondary: Color(0xFFB06BFF),
    onSecondary: Color(0xFF1B0040),
    secondaryContainer: Color(0xFF2E1A5C),
    onSecondaryContainer: Color(0xFFE1D0FF),
    tertiary: Color(0xFF52FFB3),
    onTertiary: Color(0xFF003822),
    tertiaryContainer: Color(0xFF0A4D33),
    onTertiaryContainer: Color(0xFFB3FFD9),
    error: Color(0xFFFF6B6B),
    onError: Colors.white,
    surface: Color(0xFF14151A),
    onSurface: Color(0xFFF0F2F5),
    surfaceContainerHighest: Color(0xFF1D1E24),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF3A3B44),
    outlineVariant: Color(0xFF2A2B33),
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceContainer: Color(0xFF1A1B21),
    surfaceContainerHigh: Color(0xFF1E1F26),
    surfaceContainerLow: Color(0xFF111218),
  );

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: Color(0xFF2C8FD9),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD5ECFF),
    onPrimaryContainer: Color(0xFF001D30),
    secondary: Color(0xFF8A52D9),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFEADDFF),
    onSecondaryContainer: Color(0xFF2A0052),
    tertiary: Color(0xFF0A9F6E),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFC8F5E5),
    onTertiaryContainer: Color(0xFF002C1D),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    surface: Color(0xFFF6F8FC),
    onSurface: Color(0xFF1A1B21),
    surfaceContainerHighest: Color(0xFFE8EAF0),
    onSurfaceVariant: Color(0xFF4A4C54),
    outline: Color(0xFFB0B3BC),
    outlineVariant: Color(0xFFD4D6DE),
    shadow: Colors.black,
    scrim: Colors.black,
  );
}
