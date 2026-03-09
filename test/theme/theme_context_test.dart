import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/app_theme.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';

void main() {
  testWidgets('theme context exposes semantic tokens', (tester) async {
    late AppSemanticColorsSnapshot snapshot;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) {
          AppScale.init(context);
          snapshot = AppSemanticColorsSnapshot(
            spacingM: context.spacing.m,
            radiusCard: context.radius.card,
            textPrimary: context.colors.textPrimary,
            motionFast: context.motion.fast,
          );
          return child ?? const SizedBox.shrink();
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
