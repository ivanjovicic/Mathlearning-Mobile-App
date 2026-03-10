import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/screens/quiz_screen.dart';

void main() {
  testWidgets('QuizBody renders question stem math consistently', (tester) async {
    final semantics = tester.ensureSemantics();

    final question = Question(
      id: 1,
      text: r'Compute $x^2$ when x = 4',
      options: const <Option>[],
      correctAnswerId: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuizBody(question: question)),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(
      find.bySemanticsLabel('Compute x to the power of 2 when x = 4'),
      findsOneWidget,
    );

    semantics.dispose();
  });
}
