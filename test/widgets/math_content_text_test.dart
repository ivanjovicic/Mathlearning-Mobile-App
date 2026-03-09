import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/math_content_text.dart';

void main() {
  testWidgets('renders inline latex as readable mixed text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentText(
            value: r'Compute derivative of $f(x)=x^2$ at $x=5$.',
          ),
        ),
      ),
    );

    expect(
      find.text(
        'Compute derivative of f(x)=x^2 at x=5.',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders pure latex with Math widget', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentText(
            value: r'\frac{-b\pm\sqrt{b^2-4ac}}{2a}',
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
  });
}
