import 'package:flutter/material.dart';

import 'semantic_colors_extension.dart';

class LeaderboardThemeExtension extends ThemeExtension<LeaderboardThemeExtension> {
  const LeaderboardThemeExtension({
    required this.gold,
    required this.silver,
    required this.bronze,
    required this.currentUserHighlight,
  });

  final Color gold;
  final Color silver;
  final Color bronze;
  final Color currentUserHighlight;

  factory LeaderboardThemeExtension.fromColors(AppSemanticColors colors) {
    return LeaderboardThemeExtension(
      gold: colors.leaderboardGold,
      silver: colors.leaderboardSilver,
      bronze: colors.leaderboardBronze,
      currentUserHighlight: colors.cardBackground.withValues(alpha: 0.82),
    );
  }

  @override
  LeaderboardThemeExtension copyWith({
    Color? gold,
    Color? silver,
    Color? bronze,
    Color? currentUserHighlight,
  }) {
    return LeaderboardThemeExtension(
      gold: gold ?? this.gold,
      silver: silver ?? this.silver,
      bronze: bronze ?? this.bronze,
      currentUserHighlight: currentUserHighlight ?? this.currentUserHighlight,
    );
  }

  @override
  LeaderboardThemeExtension lerp(
    ThemeExtension<LeaderboardThemeExtension>? other,
    double t,
  ) {
    if (other is! LeaderboardThemeExtension) return this;
    return LeaderboardThemeExtension(
      gold: Color.lerp(gold, other.gold, t)!,
      silver: Color.lerp(silver, other.silver, t)!,
      bronze: Color.lerp(bronze, other.bronze, t)!,
      currentUserHighlight: Color.lerp(
        currentUserHighlight,
        other.currentUserHighlight,
        t,
      )!,
    );
  }
}
