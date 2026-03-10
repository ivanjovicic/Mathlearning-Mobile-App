import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/gamified_math_panel.dart';

void main() {
  testWidgets('renders inline prompt with readable semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GamifiedMathPanel(
            formula:
                r'LaTeX test: Compute the derivative of $f(x)=x^2$ at x = 5.',
            title: 'Challenge',
            subtitle: 'Solve it',
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'LaTeX test: Compute the derivative of f(x)=x to the power of 2 at x = 5.',
      ),
      findsOneWidget,
    );

    semantics.dispose();
  });

  testWidgets('renders complex pure latex expression with Math widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GamifiedMathPanel(
            formula: r'\frac{-b\pm\sqrt{b^2-4ac}}{2a}',
            title: 'Challenge',
            subtitle: 'Solve it',
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
