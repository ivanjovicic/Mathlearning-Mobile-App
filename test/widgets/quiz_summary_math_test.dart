import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/screens/quiz_summary_screen.dart';
import 'package:mathlearning/state/settings_provider.dart';

void main() {
  testWidgets('renders review math safely in summary screen', (tester) async {
    final stats = QuizSessionStats(
      correct: 2,
      total: 4,
      xpEarned: 20,
      streak: 3,
      masteryProgress: 0.5,
      wrongQuestions: const <WrongQuestion>[
        WrongQuestion(
          questionId: 1,
          questionText: r'Compute $x^2$ when x = 4',
          userAnswer: '8',
          correctAnswer: '16',
        ),
        WrongQuestion(
          questionId: 2,
          questionText: r'\frac{1}{2} + \frac{1}{3}',
          userAnswer: r'\frac{2}{5}',
          correctAnswer: r'\frac{5}{6}',
        ),
      ],
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: QuizSummaryScreen(initialStats: stats),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Math), findsWidgets);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
