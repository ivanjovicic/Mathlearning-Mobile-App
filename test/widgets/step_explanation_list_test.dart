import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/step_explanation.dart';
import 'package:mathlearning/widgets/explanations/step_explanation_controller.dart';
import 'package:mathlearning/widgets/explanations/step_explanation_list.dart';

void main() {
  final sampleSteps = <StepExplanation>[
    const StepExplanation(
      text: 'Move constants to the right side.',
      hint: 'Subtract 4 from both sides.',
      highlight: true,
    ),
    const StepExplanation(
      text: 'Divide both sides by 2 to isolate x.',
      hint: 'Keep equation balanced.',
    ),
    const StepExplanation(text: r'x = \frac{6}{2} = 3', highlight: true),
  ];

  testWidgets('progresses through steps with buttons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StepExplanationList(steps: sampleSteps)),
      ),
    );

    expect(find.text('Move constants to the right side.'), findsOneWidget);

    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    expect(find.text('Divide both sides by 2 to isolate x.'), findsOneWidget);

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(find.text('Move constants to the right side.'), findsOneWidget);
  });

  testWidgets('supports swipe navigation and hint expansion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StepExplanationList(steps: sampleSteps)),
      ),
    );

    await tester.drag(find.byType(StepExplanationList), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Divide both sides by 2 to isolate x.'), findsOneWidget);

    await tester.tap(find.text('Show Hint'));
    await tester.pumpAndSettle();

    expect(find.text('Keep equation balanced.'), findsOneWidget);
  });

  testWidgets('shows mistake explanation mode when enabled', (tester) async {
    final controller = StepExplanationController(steps: sampleSteps)
      ..setMistakeMode(true, type: MistakeType.signError);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepExplanationList(
            steps: sampleSteps,
            controller: controller,
            mistakeExplanation:
                'You likely moved a term across "=" without changing its sign.',
            misconception: 'Moving terms requires sign inversion.',
          ),
        ),
      ),
    );

    expect(find.text('Why your answer was incorrect'), findsOneWidget);
    expect(find.textContaining('sign error'), findsOneWidget);
  });
}
