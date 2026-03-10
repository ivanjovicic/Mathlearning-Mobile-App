import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/math/math_view_mode.dart';
import 'package:mathlearning/widgets/math_content_text.dart';

void main() {
  testWidgets('renders inline latex with math widgets and readable semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentText(
            value: r'Compute $x^2$ when x = 4.',
            mode: MathViewMode.questionStem,
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(
      find.bySemanticsLabel('Compute x to the power of 2 when x = 4.'),
      findsOneWidget,
    );

    semantics.dispose();
  });

  testWidgets('renders pure latex with Math widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentText(
            value: r'\frac{-b\pm\sqrt{b^2-4ac}}{2a}',
            mode: MathViewMode.questionStem,
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
  });
}
