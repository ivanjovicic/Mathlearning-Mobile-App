import 'package:flutter/material.dart';

import 'app_scale.dart';
import 'theme_extensions/leaderboard_theme_extension.dart';
import 'theme_extensions/learning_theme_extension.dart';
import 'theme_extensions/semantic_colors_extension.dart';
import 'theme_extensions/status_theme_extension.dart';

/// Adds ThemeExtensions (SemanticColors, Status, Leaderboard, Learning)
/// and responsive font scaling to a base theme from [ThemeController].
///
/// High-contrast and typography are handled upstream:
/// - HC: [ThemeController._buildHighContrastTheme]
/// - Typography: [theme_factory.dart] via [TypographyConfig]
/// - Responsive scaling: [AppScale.scaleTextTheme] (preserves per-theme fonts)
class AppTheme {
  const AppTheme._();

  /// Adds semantic theme extensions and applies responsive font scaling.
  /// Per-theme font families are preserved; only sizes are scaled via [AppScale].
  static ThemeData enhance(ThemeData baseTheme) {
    final colorScheme = baseTheme.colorScheme;
    final semanticColors = AppSemanticColors.fromColorScheme(colorScheme);
    final extensions = <ThemeExtension>[
      semanticColors,
      StatusThemeExtension.fromColors(semanticColors),
      LeaderboardThemeExtension.fromColors(semanticColors),
      LearningThemeExtension.fromColors(semanticColors),
    ];

    final scaledTextTheme = AppScale.scaleTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      textTheme: scaledTextTheme,
      scaffoldBackgroundColor: semanticColors.screenBackground,
      extensions: extensions.cast<ThemeExtension<dynamic>>(),
    );
  }
}
