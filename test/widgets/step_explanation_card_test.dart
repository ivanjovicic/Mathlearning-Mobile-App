import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/step_explanation.dart';
import 'package:mathlearning/widgets/explanations/step_explanation_card.dart';

void main() {
  testWidgets('renders step number and highlight indicator', (tester) async {
    var hintVisible = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return StepExplanationCard(
                step: const StepExplanation(
                  text: '2x + 4 = 10',
                  hint: 'Subtract 4 from both sides.',
                  highlight: true,
                ),
                stepNumber: 1,
                totalSteps: 3,
                isHintVisible: hintVisible,
                onHintToggle: () {
                  setState(() {
                    hintVisible = !hintVisible;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Step 1'), findsOneWidget);
    expect(find.text('Important'), findsOneWidget);
    expect(find.text('Show Hint'), findsOneWidget);

    await tester.tap(find.text('Show Hint'));
    await tester.pumpAndSettle();

    expect(find.text('Hide Hint'), findsOneWidget);
    expect(find.text('Subtract 4 from both sides.'), findsOneWidget);
  });

  testWidgets('renders formula widget for math-focused step text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StepExplanationCard(
            step: StepExplanation(text: r'x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}'),
            stepNumber: 2,
            totalSteps: 4,
            isHintVisible: false,
            onHintToggle: _noop,
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsWidgets);
  });

  testWidgets('renders inline latex inside step text with readable semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    var hintVisible = true;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return StepExplanationCard(
                step: const StepExplanation(
                  text: r'Compute $f(x)=x^2$ at x = 5.',
                  hint: "Use \$f'(x)=2x\$ and then substitute \$x=5\$.",
                ),
                stepNumber: 1,
                totalSteps: 1,
                isHintVisible: hintVisible,
                onHintToggle: () {
                  setState(() {
                    hintVisible = !hintVisible;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsWidgets);

    semantics.dispose();
  });
}

void _noop() {}
