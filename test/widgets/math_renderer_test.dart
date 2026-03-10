import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/math/math_renderer.dart';
import 'package:mathlearning/widgets/math/math_view_mode.dart';

void main() {
  testWidgets('renders mixed text with inline math semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathRenderer(
            value: r'Compute $x^2$ when x = 4',
            mode: MathViewMode.questionStem,
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(
      find.bySemanticsLabel('Compute x to the power of 2 when x = 4'),
      findsOneWidget,
    );

    semantics.dispose();
  });

  testWidgets('falls back safely for malformed tex', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathRenderer(
            value: r'\unknowncommand{1}',
            mode: MathViewMode.review,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('unknowncommand'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses horizontal scroll only for very large display math', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 240,
          child: Scaffold(
            body: MathRenderer(
              value:
                  r'\begin{cases}x^2 + y^2 = 1\\2x + 3y = \frac{10}{3}\end{cases}',
              mode: MathViewMode.questionStem,
              forceDisplay: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
