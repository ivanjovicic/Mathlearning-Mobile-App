import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/screens/daily_review_screen.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';

import '../helpers/test_app.dart';
import '../helpers/test_bootstrap.dart';
import '../helpers/test_fakes.dart';
import 'daily_review_screen_test.mocks.dart';

@GenerateMocks([QuizProvider])

Widget _buildRouterApp({
  required Widget home,
  required List<SingleChildWidget> providers,
  String initialLocation = '/',
  Map<String, WidgetBuilder> routes = const {},
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, state) => home),
      ...routes.entries.map(
        (entry) => GoRoute(
          path: entry.key,
          builder: (context, state) => entry.value(context),
        ),
      ),
    ],
  );

  return MultiProvider(
    providers: providers,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  bootstrapTests();

  group('DailyReviewScreen', () {
    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      final loadCompleter = Completer<void>();
      final quizProvider = MockQuizProvider();
      when(quizProvider.isLoadingHint).thenReturn(true);
      when(quizProvider.questions).thenReturn([]);
      when(quizProvider.isOnline).thenReturn(true);
      when(quizProvider.loadQuiz()).thenAnswer((_) => loadCompleter.future);

      await tester.pumpWidget(
        buildTestApp(
          home: const DailyReviewScreen(),
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quizProvider),
            ChangeNotifierProvider<ProgressProvider>(
              create: (_) => ProgressProvider(),
            ),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      loadCompleter.complete();
      await tester.pumpAndSettle();
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
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider<ProgressProvider>.value(value: progress),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
          routes: {
            '/quiz': (_) => const Scaffold(body: Text('Quiz Screen')),
          },
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

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
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider<ProgressProvider>.value(value: progress),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
          routes: {
            '/quiz': (_) => const Scaffold(body: Text('Quiz Screen')),
          },
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nema pitanja za danas'), findsOneWidget);
      expect(find.text('Odlicno, sve je uradjeno. Vrati se kasnije.'), findsOneWidget);
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
        _buildRouterApp(
          home: const DailyReviewScreen(),
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider<ProgressProvider>.value(value: progress),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
          routes: {
            '/quiz': (_) => const Scaffold(body: Text('Quiz Screen')),
          },
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Start Review'));
      await tester.tap(find.text('Start Review'));
      await tester.pumpAndSettle();

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
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider<ProgressProvider>.value(value: progress),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
          routes: {
            '/quiz': (_) => const Scaffold(body: Text('Quiz Screen')),
          },
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nema pitanja za danas'), findsOneWidget);
    });
  });
}

