import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/explanations/mistake_explanation_card.dart';
import 'package:mathlearning/widgets/explanations/step_explanation_controller.dart';

void main() {
  testWidgets('renders math in explanation and answer pills', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MistakeExplanationCard(
            explanation: r'You should simplify $x^2$ before substitution.',
            misconception: r'It is not valid to treat $\frac{1}{2}$ as 2.',
            mistakeType: MistakeType.orderOfOperations,
            studentAnswer: r'\frac{2}{1}',
            expectedAnswer: r'\frac{1}{2}',
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsWidgets);
    expect(find.text('Why your answer was incorrect'), findsOneWidget);
  });
}
