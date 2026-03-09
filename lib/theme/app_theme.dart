import 'package:flutter/material.dart';

import 'app_theme_dark.dart';
import 'app_theme_light.dart';
import 'theme_extensions/leaderboard_theme_extension.dart';
import 'theme_extensions/learning_theme_extension.dart';
import 'theme_extensions/semantic_colors_extension.dart';
import 'theme_extensions/status_theme_extension.dart';
import 'tokens/app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light({bool highContrast = false}) {
    return AppThemeLight.build(highContrast: highContrast);
  }

  static ThemeData dark({bool highContrast = false}) {
    return AppThemeDark.build(highContrast: highContrast);
  }

  static ThemeData enhance(
    ThemeData baseTheme, {
    bool highContrast = false,
  }) {
    final colorScheme = highContrast
        ? _withHighContrast(baseTheme.colorScheme)
        : baseTheme.colorScheme;
    final semanticColors = AppSemanticColors.fromColorScheme(colorScheme);
    final extensions = <ThemeExtension>[
      semanticColors,
      StatusThemeExtension.fromColors(semanticColors),
      LeaderboardThemeExtension.fromColors(semanticColors),
      LearningThemeExtension.fromColors(semanticColors),
    ];

    return baseTheme.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: semanticColors.screenBackground,
      textTheme: AppTypography.scaleTheme(baseTheme.textTheme, colorScheme),
      primaryTextTheme: AppTypography.scaleTheme(
        baseTheme.primaryTextTheme,
        colorScheme,
      ),
      extensions: extensions.cast<ThemeExtension<dynamic>>(),
    );
  }

  static ColorScheme _withHighContrast(ColorScheme scheme) {
    Color contrastFor(Color color) {
      return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? Colors.white
          : Colors.black;
    }

    return scheme.copyWith(
      onPrimary: contrastFor(scheme.primary),
      onSecondary: contrastFor(scheme.secondary),
      onTertiary: contrastFor(scheme.tertiary),
      onSurface: contrastFor(scheme.surface),
      onError: contrastFor(scheme.error),
      onPrimaryContainer: contrastFor(scheme.primaryContainer),
      onSecondaryContainer: contrastFor(scheme.secondaryContainer),
      onTertiaryContainer: contrastFor(scheme.tertiaryContainer),
      onErrorContainer: contrastFor(scheme.errorContainer),
      onSurfaceVariant: contrastFor(scheme.surfaceContainerHighest),
      outline: contrastFor(scheme.surface).withValues(alpha: 0.72),
      outlineVariant: contrastFor(scheme.surface).withValues(alpha: 0.44),
    );
  }
}
