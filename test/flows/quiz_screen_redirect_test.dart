import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/screens/daily_review_screen.dart';
import 'package:mathlearning/screens/quiz_screen.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';

import '../helpers/test_app.dart';
import '../helpers/test_bootstrap.dart';
import '../helpers/test_fakes.dart';

void main() {
  bootstrapTests();

  group('QuizScreen daily review redirect', () {
    testWidgets('redirects to /daily-review when SRS count > 0', (
      tester,
    ) async {
      final quiz = TestQuizProvider(onGetDailySrsCount: () async => 3);

      await tester.pumpWidget(
        buildGoRouterTestApp(
          initialLocation: '/quiz/new',
          routes: [
            GoRoute(
              path: '/quiz/:quizSessionId',
              builder: (_, _) => const QuizScreen(),
            ),
            GoRoute(
              path: '/home/daily-review',
              builder: (_, _) => const Scaffold(
                body: Center(child: Text('Daily Review Route')),
              ),
            ),
          ],
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
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
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      // Advance time past all async hops and animations (500 ms covers the
      // 300ms AnimatedSwitcher and 500ms TweenAnimationBuilder in QuizHeader)
      await tester.pump(const Duration(milliseconds: 500));

      // QuizScreen stays and loads the question (no redirect)
      expect(find.text('Koliko je 2 + 2?'), findsOneWidget);
    });

    testWidgets('skipDailyReviewOnce prevents redirect', (tester) async {
      // Provide an explicit question so totalQuestions=1 (avoids NaN in
      // QuizHeader's progress = questionNumber / totalQuestions when 0).
      final quiz = TestQuizProvider(
        onGetDailySrsCount: () async => 5,
        quizQuestions: [
          Question(
            id: 1,
            text: 'Koliko je 2 + 2?',
            correctAnswerId: 1,
            options: [
              Option(id: 1, text: '4'),
              Option(id: 2, text: '3'),
            ],
          ),
        ],
      );
      quiz.skipDailyReviewOnce();

      await tester.pumpWidget(
        buildTestApp(
          home: const QuizScreen(),
          routes: {
            '/daily-review': (_) =>
                const Scaffold(body: Center(child: Text('Daily Review Route'))),
          },
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      // QuizScreen stays (no redirect), getDailySrsCount was never called
      expect(find.text('Koliko je 2 + 2?'), findsOneWidget);
      expect(quiz.getDailySrsCountCalls, 0);
    });

    testWidgets('DailyReview -> Quiz does not loop back to DailyReview', (
      tester,
    ) async {
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
        buildGoRouterTestApp(
          initialLocation: '/home/daily-review',
          routes: [
            GoRoute(
              path: '/home/daily-review',
              builder: (_, _) => const DailyReviewScreen(),
            ),
            GoRoute(
              path: '/quiz/:quizSessionId',
              builder: (_, state) {
                final skip = state.queryParameters['skipDailyReview'] == '1';
                return QuizScreen(skipDailyReviewRedirect: skip);
              },
            ),
          ],
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll the Start Review button into view before tapping
      await tester.scrollUntilVisible(
        find.text('Start Review'),
        50.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();

      await tester.tap(find.text('Start Review'), warnIfMissed: false);
      await tester.pump(); // register tap + let GoRouter schedule navigation
      await tester.pump(const Duration(milliseconds: 500));

      // QuizScreen should start without redirecting back.
      expect(find.byType(QuizScreen), findsOneWidget);
      expect(quiz.getDailySrsCountCalls, 0);
    });
  });
}
