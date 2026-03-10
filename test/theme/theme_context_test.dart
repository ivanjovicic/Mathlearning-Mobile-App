import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/app_theme.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';
import 'package:mathlearning/theme/themes/scifi_theme.dart';

void main() {
  testWidgets('theme context exposes semantic tokens', (tester) async {
    late AppSemanticColorsSnapshot snapshot;

    await tester.pumpWidget(
      MaterialApp(
        theme: SciFiTheme.data,
        builder: (context, child) {
          AppScale.init(context);
          final enhanced = AppTheme.enhance(Theme.of(context));
          return Theme(
            data: enhanced,
            child: Builder(builder: (innerContext) {
              snapshot = AppSemanticColorsSnapshot(
                spacingM: innerContext.spacing.m,
                radiusCard: innerContext.radius.card,
                textPrimary: innerContext.colors.textPrimary,
                motionFast: innerContext.motion.fast,
              );
              return child ?? const SizedBox.shrink();
            }),
          );
        },
        home: const Scaffold(body: SizedBox()),
      ),
    );

    expect(snapshot.spacingM, greaterThan(0));
    expect(snapshot.radiusCard, greaterThan(0));
    expect(snapshot.textPrimary, isNotNull);
    expect(snapshot.motionFast, const Duration(milliseconds: 160));
  });
}

class AppSemanticColorsSnapshot {
  AppSemanticColorsSnapshot({
    required this.spacingM,
    required this.radiusCard,
    required this.textPrimary,
    required this.motionFast,
  });

  final double spacingM;
  final double radiusCard;
  final Color textPrimary;
  final Duration motionFast;
}
