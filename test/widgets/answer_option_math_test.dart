import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/ui/answer_option_card.dart';

void main() {
  testWidgets('answer option renders short math inline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnswerOptionCard(
            text: r'\frac{1}{2}',
            selected: false,
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
  });

  testWidgets('answer option remains stable on small width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: const MaterialApp(
          home: Scaffold(
            body: AnswerOptionCard(
              text: r'\frac{-b\pm\sqrt{b^2-4ac}}{2a}',
              selected: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
