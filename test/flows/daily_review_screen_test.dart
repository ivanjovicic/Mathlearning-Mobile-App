import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/screens/daily_review_screen.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';

import '../helpers/test_app.dart';
import '../helpers/test_bootstrap.dart';
import '../helpers/test_fakes.dart';
import 'daily_review_screen_test.mocks.dart';

@GenerateMocks([QuizProvider])
void main() {
  bootstrapTests();

  group('DailyReviewScreen', () {
    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      // Arrange
      final quizProvider = MockQuizProvider();
      when(quizProvider.isLoadingHint).thenReturn(true);
      when(quizProvider.questions).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<QuizProvider>.value(
          value: quizProvider,
          child: const MaterialApp(
            home: DailyReviewScreen(),
          ),
        ),
      );

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows count and preview after load', (tester) async {
      final quiz = TestQuizProvider(
        reviewQuestions: [
          Question(
            id: 1,
            text: 'Koliko je 2 + 2?',
            correctAnswerId: 1,
            options: [Option(id: 1, text: '4')],
          ),
          Question(
            id: 2,
            text: 'Koliko je 5 + 1?',
            correctAnswerId: 2,
            options: [Option(id: 2, text: '6')],
          ),
        ],
      );
      final progress = ProgressProvider()..streak = 3;

      await tester.pumpWidget(
        buildTestApp(
          home: const DailyReviewScreen(),
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
          ],
          routes: {
            '/quiz': (_) => const Scaffold(body: Text('Quiz Screen')),
          },
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Danas imas 2 pitanja za ponavljanje.'), findsOneWidget);
      expect(find.text('Koliko je 2 + 2?'), findsOneWidget);
      expect(find.text('Start Review'), findsOneWidget);
    });

    testWidgets('Start Review is disabled when there are no questions',
        (tester) async {
      final quiz = TestQuizProvider(reviewQuestions: []);
      final progress = ProgressProvider()..streak = 1;

      await tester.pumpWidget(
        buildTestApp(
          home: const DailyReviewScreen(),
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
          ],
          routes: {
            '/quiz': (_) => const Scaffold(body: Text('Quiz Screen')),
          },
        ),
      );

      await tester.pump();
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.text('Danas si sve zavrsio. Bravo!'), findsOneWidget);
    });

    testWidgets('Start Review navigates and sets skipDailyReviewOnce', (tester) async {
      final quiz = TestQuizProvider(
        reviewQuestions: [
          Question(
            id: 1,
            text: 'Q1',
            correctAnswerId: 1,
            options: [Option(id: 1, text: 'A')],
          ),
        ],
      );
      final progress = ProgressProvider()..streak = 2;

      await tester.pumpWidget(
        buildTestApp(
          home: const DailyReviewScreen(),
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
          ],
          routes: {
            '/quiz': (_) => const Scaffold(body: Text('Quiz Screen')),
          },
        ),
      );

      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Start Review'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Quiz Screen'), findsOneWidget);
      expect(quiz.consumeSkipDailyReviewOnce(), isTrue);
    });

    testWidgets('streak badge uses ProgressProvider streak', (tester) async {
      final quiz = TestQuizProvider(reviewQuestions: []);
      final progress = ProgressProvider()..streak = 7;

      await tester.pumpWidget(
        buildTestApp(
          home: const DailyReviewScreen(),
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
          ],
          routes: {
            '/quiz': (_) => const Scaffold(body: Text('Quiz Screen')),
          },
        ),
      );

      expect(find.text('Streak: 7 dana'), findsOneWidget);
    });
  });
}

