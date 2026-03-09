import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_scale.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme scaleTheme(TextTheme base, ColorScheme colors) {
    final bodyBase = GoogleFonts.interTextTheme(base).apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );

    return bodyBase.copyWith(
      displayLarge: _displayStyle(colors, 34, 28, 48),
      headlineLarge: _displayStyle(colors, 28, 24, 40),
      titleLarge: _titleStyle(colors, 22, 20, 30),
      titleMedium: _titleStyle(colors, 18, 16, 24),
      bodyLarge: _bodyStyle(colors, 16, 14, 22),
      bodyMedium: _bodyStyle(
        colors,
        14,
        13,
        20,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: _labelStyle(colors, 14, 12, 18),
      labelMedium: _labelStyle(
        colors,
        12,
        11,
        16,
        color: colors.onSurfaceVariant,
      ),
      labelSmall: _labelStyle(
        colors,
        11,
        10,
        14,
        color: colors.onSurfaceVariant,
      ),
      bodySmall: _captionStyle(colors, 12, 11, 16),
    );
  }

  static TextStyle _displayStyle(
    ColorScheme colors,
    double base,
    double min,
    double max,
  ) {
    return GoogleFonts.spaceGrotesk(
      fontSize: AppScale.font(base, min: min, max: max),
      fontWeight: FontWeight.w700,
      height: 1.05,
      color: colors.onSurface,
    );
  }

  static TextStyle _titleStyle(
    ColorScheme colors,
    double base,
    double min,
    double max,
  ) {
    return GoogleFonts.spaceGrotesk(
      fontSize: AppScale.font(base, min: min, max: max),
      fontWeight: FontWeight.w600,
      height: 1.15,
      color: colors.onSurface,
    );
  }

  static TextStyle _bodyStyle(
    ColorScheme colors,
    double base,
    double min,
    double max, {
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: AppScale.font(base, min: min, max: max),
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: color ?? colors.onSurface,
    );
  }

  static TextStyle _labelStyle(
    ColorScheme colors,
    double base,
    double min,
    double max, {
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: AppScale.font(base, min: min, max: max),
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: color ?? colors.onSurface,
    );
  }

  static TextStyle _captionStyle(
    ColorScheme colors,
    double base,
    double min,
    double max,
  ) {
    return GoogleFonts.inter(
      fontSize: AppScale.font(base, min: min, max: max),
      fontWeight: FontWeight.w500,
      height: 1.35,
      color: colors.onSurfaceVariant,
    );
  }
}
