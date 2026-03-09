import 'package:flutter/material.dart';

import '../app_scale.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart' as raw_spacing;
import 'leaderboard_theme_extension.dart';
import 'learning_theme_extension.dart';
import 'semantic_colors_extension.dart';
import 'status_theme_extension.dart';

class AppSpacingTokens {
  const AppSpacingTokens();

  double get xs => AppScale.s(raw_spacing.AppSpacing.xs);
  double get s => AppScale.s(raw_spacing.AppSpacing.s);
  double get m => AppScale.s(raw_spacing.AppSpacing.m);
  double get l => AppScale.s(raw_spacing.AppSpacing.l);
  double get xl => AppScale.s(raw_spacing.AppSpacing.xl);
  double get xxl => AppScale.s(raw_spacing.AppSpacing.xxl);
}

class AppRadiusTokens {
  const AppRadiusTokens();

  double get small => AppScale.radius(AppRadius.small);
  double get medium => AppScale.radius(AppRadius.medium);
  double get large => AppScale.radius(AppRadius.large);
  double get card => AppScale.radius(AppRadius.card);
  double get pill => AppScale.radius(AppRadius.pill);
}

class AppMotionTokens {
  const AppMotionTokens();

  Duration get fast => AppMotion.fast;
  Duration get normal => AppMotion.normal;
  Duration get slow => AppMotion.slow;
  Curve get standard => AppMotion.standard;
  Curve get decelerate => AppMotion.decelerate;
  Curve get emphasized => AppMotion.emphasized;
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
}
