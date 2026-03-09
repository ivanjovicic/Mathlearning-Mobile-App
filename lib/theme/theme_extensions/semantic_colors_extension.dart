import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.textPrimary,
    required this.textSecondary,
    required this.screenBackground,
    required this.cardBackground,
    required this.border,
    required this.leaderboardGold,
    required this.leaderboardSilver,
    required this.leaderboardBronze,
    required this.weaknessHigh,
    required this.masteryStrong,
    required this.success,
    required this.warning,
    required this.error,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color screenBackground;
  final Color cardBackground;
  final Color border;
  final Color leaderboardGold;
  final Color leaderboardSilver;
  final Color leaderboardBronze;
  final Color weaknessHigh;
  final Color masteryStrong;
  final Color success;
  final Color warning;
  final Color error;

  factory AppSemanticColors.fromColorScheme(ColorScheme scheme) {
    return AppSemanticColors(
      textPrimary: scheme.onSurface,
      textSecondary: scheme.onSurfaceVariant,
      screenBackground: scheme.surface,
      cardBackground: scheme.surfaceContainerHighest,
      border: scheme.outlineVariant,
      leaderboardGold: AppBaseColors.leaderboardGold,
      leaderboardSilver: AppBaseColors.leaderboardSilver,
      leaderboardBronze: AppBaseColors.leaderboardBronze,
      weaknessHigh: AppBaseColors.weaknessHigh,
      masteryStrong: AppBaseColors.masteryStrong,
      success: AppBaseColors.success,
      warning: AppBaseColors.warning,
      error: scheme.error,
    );
  }

  @override
  AppSemanticColors copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? screenBackground,
    Color? cardBackground,
    Color? border,
    Color? leaderboardGold,
    Color? leaderboardSilver,
    Color? leaderboardBronze,
    Color? weaknessHigh,
    Color? masteryStrong,
    Color? success,
    Color? warning,
    Color? error,
  }) {
    return AppSemanticColors(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      screenBackground: screenBackground ?? this.screenBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      border: border ?? this.border,
      leaderboardGold: leaderboardGold ?? this.leaderboardGold,
      leaderboardSilver: leaderboardSilver ?? this.leaderboardSilver,
      leaderboardBronze: leaderboardBronze ?? this.leaderboardBronze,
      weaknessHigh: weaknessHigh ?? this.weaknessHigh,
      masteryStrong: masteryStrong ?? this.masteryStrong,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      screenBackground: Color.lerp(screenBackground, other.screenBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      border: Color.lerp(border, other.border, t)!,
      leaderboardGold: Color.lerp(leaderboardGold, other.leaderboardGold, t)!,
      leaderboardSilver: Color.lerp(leaderboardSilver, other.leaderboardSilver, t)!,
      leaderboardBronze: Color.lerp(leaderboardBronze, other.leaderboardBronze, t)!,
      weaknessHigh: Color.lerp(weaknessHigh, other.weaknessHigh, t)!,
      masteryStrong: Color.lerp(masteryStrong, other.masteryStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
