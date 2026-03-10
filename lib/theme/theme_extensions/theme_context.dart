import 'package:flutter/material.dart';

import '../app_scale.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';
import '../tokens/breakpoint_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'leaderboard_theme_extension.dart';
import 'learning_theme_extension.dart';
import 'semantic_colors_extension.dart';
import 'status_theme_extension.dart';

class AppSpacingTokens {
  const AppSpacingTokens();

  double get xs => AppSpacing.xs;
  double get s => AppSpacing.sm;
  double get m => AppSpacing.base;
  double get l => AppSpacing.lg;
  double get xl => AppSpacing.xl;
  double get xxl => AppSpacing.xxl;
}

class AppRadiusTokens {
  const AppRadiusTokens();

  double get small => AppScale.radius(AppRadius.sm);
  double get medium => AppScale.radius(AppRadius.md);
  double get large => AppScale.radius(AppRadius.lg);
  double get card => AppScale.radius(AppRadius.xl);
  double get pill => AppScale.radius(AppRadius.full);
}

class AppMotionTokens {
  const AppMotionTokens();

  Duration get instant => AppMotion.instant;
  Duration get fast => AppMotion.fast;
  Duration get normal => AppMotion.normal;
  Duration get slow => AppMotion.slow;
  Duration get xSlow => AppMotion.xSlow;
  Curve get standard => AppMotion.standard;
  Curve get decelerate => AppMotion.decelerate;
  Curve get emphasized => AppMotion.emphasized;
  Curve get enter => AppMotion.enter;
  Curve get exit => AppMotion.exit;
}

class AppElevationTokens {
  const AppElevationTokens();

  double get level0 => AppElevation.level0;
  double get level1 => AppElevation.level1;
  double get level2 => AppElevation.level2;
  double get level3 => AppElevation.level3;
  double get level4 => AppElevation.level4;
  double get level5 => AppElevation.level5;
}

class AppShadowSet {
  const AppShadowSet(this._colors);

  final AppSemanticColors _colors;

  List<BoxShadow> get cardShadow => AppShadowTokens.cardShadow(_colors.border);
  List<BoxShadow> get elevatedShadow =>
      AppShadowTokens.elevatedShadow(_colors.border);
  List<BoxShadow> focusShadow([Color? color]) {
    return AppShadowTokens.focusShadow(color ?? _colors.masteryStrong);
  }
}

extension AppThemeContextX on BuildContext {
  AppSemanticColors get colors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      AppSemanticColors.fromColorScheme(Theme.of(this).colorScheme);

  AppSpacingTokens get spacing => const AppSpacingTokens();

  AppRadiusTokens get radius => const AppRadiusTokens();

  AppMotionTokens get motion => const AppMotionTokens();

  AppElevationTokens get elevation => const AppElevationTokens();

  AppShadowSet get shadows => AppShadowSet(colors);

  StatusThemeExtension get status =>
      Theme.of(this).extension<StatusThemeExtension>() ??
      StatusThemeExtension.fromColors(colors);

  LeaderboardThemeExtension get leaderboardTheme =>
      Theme.of(this).extension<LeaderboardThemeExtension>() ??
      LeaderboardThemeExtension.fromColors(colors);

  LearningThemeExtension get learningTheme =>
      Theme.of(this).extension<LearningThemeExtension>() ??
      LearningThemeExtension.fromColors(colors);

  // ── Responsive helpers ─────────────────────────────────────────────────

  /// Current Material 3 window-size class.
  WindowSize get windowSize => AppBreakpoints.of(this);

  /// Pick a value based on current breakpoint.
  T responsive<T>({
    required T compact,
    T? medium,
    T? expanded,
    T? large,
  }) =>
      AppBreakpoints.responsive(
        this,
        compact: compact,
        medium: medium,
        expanded: expanded,
        large: large,
      );

  /// Max content width for the current breakpoint.
  double get contentMaxWidth => AppBreakpoints.contentMaxWidth(this);

  /// Whether reduced motion is requested (platform or user preference).
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;
}
