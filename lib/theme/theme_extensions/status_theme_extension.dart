import 'package:flutter/material.dart';

import 'semantic_colors_extension.dart';

class StatusThemeExtension extends ThemeExtension<StatusThemeExtension> {
  const StatusThemeExtension({
    required this.success,
    required this.warning,
    required this.error,
    required this.focusRing,
  });

  final Color success;
  final Color warning;
  final Color error;
  final Color focusRing;

  factory StatusThemeExtension.fromColors(AppSemanticColors colors) {
    return StatusThemeExtension(
      success: colors.success,
      warning: colors.warning,
      error: colors.error,
      focusRing: colors.masteryStrong,
    );
  }

  @override
  StatusThemeExtension copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? focusRing,
  }) {
    return StatusThemeExtension(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      focusRing: focusRing ?? this.focusRing,
    );
  }

  @override
  StatusThemeExtension lerp(
    ThemeExtension<StatusThemeExtension>? other,
    double t,
  ) {
    if (other is! StatusThemeExtension) return this;
    return StatusThemeExtension(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
    );
  }
}
