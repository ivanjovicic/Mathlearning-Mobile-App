import 'package:flutter/material.dart';

import '../app_scale.dart';
import 'app_colors.dart';

class AppShadowTokens {
  const AppShadowTokens._();

  static List<BoxShadow> cardShadow([Color color = AppBaseColors.neutral950]) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.08),
        blurRadius: AppScale.s(16),
        offset: Offset(0, AppScale.s(6)),
      ),
    ];
  }

  static List<BoxShadow> elevatedShadow([
    Color color = AppBaseColors.neutral950,
  ]) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.12),
        blurRadius: AppScale.s(24),
        offset: Offset(0, AppScale.s(10)),
      ),
    ];
  }

  static List<BoxShadow> focusShadow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.22),
        blurRadius: AppScale.s(18),
        spreadRadius: AppScale.s(1),
      ),
    ];
  }
}

class AppShadowTheme extends ThemeExtension<AppShadowTheme> {
  const AppShadowTheme();

  @override
  AppShadowTheme copyWith() => const AppShadowTheme();

  @override
  AppShadowTheme lerp(ThemeExtension<AppShadowTheme>? other, double t) {
    return const AppShadowTheme();
  }
}
