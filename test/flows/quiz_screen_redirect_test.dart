import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/screens/daily_review_screen.dart';
import 'package:mathlearning/screens/home/gamified_quiz_screen.dart';
import 'package:mathlearning/screens/quiz_screen.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';

import '../helpers/test_app.dart';
import '../helpers/test_bootstrap.dart';
import '../helpers/test_fakes.dart';

void main() {
  bootstrapTests();

  group('QuizScreen daily review redirect', () {
    testWidgets('redirects to /daily-review when SRS count > 0', (tester) async {
      final quiz = TestQuizProvider(onGetDailySrsCount: () async => 3);

      await tester.pumpWidget(
        buildTestApp(
          home: const QuizScreen(),
          routes: {
            '/daily-review': (_) =>
                const Scaffold(body: Center(child: Text('Daily Review Route'))),
          },
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Daily Review Route'), findsOneWidget);
    });

    testWidgets('does not redirect when SRS count is 0', (tester) async {
      final quiz = TestQuizProvider(
        onGetDailySrsCount: () async => 0,
        quizQuestions: [
          Question(
            id: 1,
            text: 'Koliko je 2 + 2?',
            correctAnswerId: 1,
            options: [Option(id: 1, text: '4')],
          ),
        ],
      );

      await tester.pumpWidget(
        buildTestApp(
          home: const QuizScreen(),
          routes: {
            '/daily-review': (_) =>
                const Scaffold(body: Center(child: Text('Daily Review Route'))),
          },
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(GamifiedQuizScreen), findsOneWidget);
    });

    testWidgets('skipDailyReviewOnce prevents redirect', (tester) async {
      final quiz = TestQuizProvider(onGetDailySrsCount: () async => 5);
      quiz.skipDailyReviewOnce();

      await tester.pumpWidget(
        buildTestApp(
          home: const QuizScreen(),
          routes: {
            '/daily-review': (_) =>
                const Scaffold(body: Center(child: Text('Daily Review Route'))),
          },
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(GamifiedQuizScreen), findsOneWidget);
      expect(quiz.getDailySrsCountCalls, 0);
    });

    testWidgets('DailyReview -> Quiz does not loop back to DailyReview',
        (tester) async {
      final quiz = TestQuizProvider(
        onGetDailySrsCount: () async => 5,
        reviewQuestions: [
          Question(
            id: 1,
            text: 'Q1',
            correctAnswerId: 1,
            options: [Option(id: 1, text: 'A')],
          ),
        ],
      );
      final progress = ProgressProvider()..streak = 4;

      await tester.pumpWidget(
        buildTestApp(
          home: const DailyReviewScreen(),
          routes: {
            '/quiz': (_) => const QuizScreen(),
            '/daily-review': (_) => const DailyReviewScreen(),
          },
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Start Review'));
      await tester.pump(const Duration(milliseconds: 500));

      // QuizScreen should start without redirecting back.
      await tester.pump();
      await tester.pump();

      expect(find.byType(GamifiedQuizScreen), findsOneWidget);
      expect(quiz.getDailySrsCountCalls, 0);
    });
  });
}

