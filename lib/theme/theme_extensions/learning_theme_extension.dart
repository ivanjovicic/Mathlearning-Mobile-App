import 'package:flutter/material.dart';

import 'semantic_colors_extension.dart';

class LearningThemeExtension extends ThemeExtension<LearningThemeExtension> {
  const LearningThemeExtension({
    required this.weaknessHigh,
    required this.masteryStrong,
    required this.reviewAccent,
  });

  final Color weaknessHigh;
  final Color masteryStrong;
  final Color reviewAccent;

  factory LearningThemeExtension.fromColors(AppSemanticColors colors) {
    return LearningThemeExtension(
      weaknessHigh: colors.weaknessHigh,
      masteryStrong: colors.masteryStrong,
      reviewAccent: colors.warning,
    );
  }

  @override
  LearningThemeExtension copyWith({
    Color? weaknessHigh,
    Color? masteryStrong,
    Color? reviewAccent,
  }) {
    return LearningThemeExtension(
      weaknessHigh: weaknessHigh ?? this.weaknessHigh,
      masteryStrong: masteryStrong ?? this.masteryStrong,
      reviewAccent: reviewAccent ?? this.reviewAccent,
    );
  }

  @override
  LearningThemeExtension lerp(
    ThemeExtension<LearningThemeExtension>? other,
    double t,
  ) {
    if (other is! LearningThemeExtension) return this;
    return LearningThemeExtension(
      weaknessHigh: Color.lerp(weaknessHigh, other.weaknessHigh, t)!,
      masteryStrong: Color.lerp(masteryStrong, other.masteryStrong, t)!,
      reviewAccent: Color.lerp(reviewAccent, other.reviewAccent, t)!,
    );
  }
}
