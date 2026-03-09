import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/gamified_math_panel.dart';

void main() {
  testWidgets('renders inline latex prompt as readable full text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GamifiedMathPanel(
            formula:
                r'LaTeX test: Compute the derivative of $f(x)=x^2$ at $x=5$.',
            title: 'Challenge',
            subtitle: 'Solve it',
          ),
        ),
      ),
    );

    expect(
      find.text(
        'LaTeX test: Compute the derivative of f(x)=x^2 at x=5.',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders pure latex expression with Math widget', (tester) async {
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
  });
}
