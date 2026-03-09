import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/theme/app_scale.dart';

void main() {
  testWidgets('computes fluid scale from screen width', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 640),
          textScaler: TextScaler.linear(1),
        ),
        child: Builder(
          builder: (context) {
            AppScale.init(context);
            expect(AppScale.scale, closeTo(320 / 390, 0.001));
            expect(AppScale.s(16), closeTo(16 * (320 / 390), 0.01));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('clamps typography scaling for accessibility', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(1024, 768),
          textScaler: TextScaler.linear(1.8),
        ),
        child: Builder(
          builder: (context) {
            AppScale.init(context);
            expect(AppScale.font(24, min: 22, max: 36), 36);
            expect(AppScale.font(12, min: 11, max: 16), 16);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
