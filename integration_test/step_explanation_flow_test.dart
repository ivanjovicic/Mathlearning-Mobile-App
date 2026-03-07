import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mathlearning/models/step_explanation.dart';
import 'package:mathlearning/widgets/explanations/step_explanation_list.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('step progression works with button and swipe navigation', (
    tester,
  ) async {
    const steps = <StepExplanation>[
      StepExplanation(text: 'Step A: simplify left side.'),
      StepExplanation(text: 'Step B: isolate x.', hint: 'Subtract constants.'),
      StepExplanation(text: r'Step C: x = \frac{8}{2} = 4', highlight: true),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StepExplanationList(steps: steps)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Step A'), findsOneWidget);

    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step B'), findsOneWidget);

    await tester.drag(find.byType(StepExplanationList), const Offset(-280, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining(r'x = \frac{8}{2} = 4'), findsOneWidget);

    await tester.drag(find.byType(StepExplanationList), const Offset(280, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Step B'), findsOneWidget);
  });
}
