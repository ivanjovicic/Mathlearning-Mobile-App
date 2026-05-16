import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/screens/home/gamified_quiz_screen.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';
import 'package:mathlearning/widgets/game_button.dart';
import 'package:mathlearning/widgets/mastery_burst.dart';
import 'package:mathlearning/widgets/streak_flame.dart';

import '../helpers/test_app.dart';
import '../helpers/test_bootstrap.dart';
import '../helpers/test_fakes.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'gamified_quiz_feedback_test.mocks.dart';

import '../test_helper.dart';

@GenerateMocks([FlutterSecureStorage])
Future<void> main() async {
  setupGlobalMocks();

  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    when(mockSecureStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value'))).thenAnswer((_) async {});
    when(mockSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  await bootstrapTests();

  GamifiedQuizScreen buildScreen() {
    return GamifiedQuizScreen(
      question: Question(
        id: 1,
        text: r'2+2',
        options: [
          Option(id: 1, text: '4'),
          Option(id: 2, text: '3'),
        ],
        correctAnswerId: 1,
      ),
      questionNumber: 1,
      totalQuestions: 10,
      xpReward: 20,
      options: [
        OptionItem(id: '1', text: '4', isCorrect: true),
        OptionItem(id: '2', text: '3', isCorrect: false),
      ],
      onSubmit: (_) async {},
    );
  }

  Finder gameButtonByText(String text) {
    return find.byWidgetPredicate(
      (w) => w is GameButton && w.text == text,
      description: 'GameButton(text: "$text")',
    );
  }

  group('GamifiedQuizScreen feedback', () {
    testWidgets('shows mastery label localized (sr) and starts at 0%',
        (tester) async {
      final quiz = TestQuizProvider();
      final progress = ProgressProvider()..streak = 3;

      await tester.pumpWidget(
        buildTestApp(
          home: buildScreen(),
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Savladanost'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('correct answer shows XP pop + streak flame and mastery updates', (tester) async {
      // Force portrait layout so options render in single-column (easier to tap)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final quiz = TestQuizProvider();
      final progress = ProgressProvider()..streak = 3;

      await tester.pumpWidget(
        buildTestApp(
          home: buildScreen(),
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.tap(gameButtonByText('4'));
      await tester.pump();

      // xpReward(20) + no-hint bonus(5) = 25 XP on first correct answer
      expect(find.text('+25 XP'), findsOneWidget);
      expect(find.byType(StreakFlame), findsOneWidget);
      expect(find.text('12%'), findsOneWidget);

      // Drain overlay auto-remove timers (max 900 ms)
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('wrong answer shows localized try-again XP pop', (tester) async {
      // Force portrait layout so options render in single-column (easier to tap)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final quiz = TestQuizProvider();
      final progress = ProgressProvider()..streak = 3;

      await tester.pumpWidget(
        buildTestApp(
          home: buildScreen(),
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.tap(gameButtonByText('3'));
      await tester.pump();

      expect(find.text('Pokusaj ponovo'), findsOneWidget);

      // Drain overlay auto-remove timers (max 900 ms)
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shows mastery burst when crossing 50%', (tester) async {
      // Force portrait layout so options render in single-column (easier to tap)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final quiz = TestQuizProvider();
      final progress = ProgressProvider()..streak = 3;

      // Build up to 48%.
      for (var i = 0; i < 4; i++) {
        quiz.applyMasteryDelta(isCorrect: true);
      }

      await tester.pumpWidget(
        buildTestApp(
          home: buildScreen(),
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.tap(gameButtonByText('4'));
      await tester.pump();

      expect(find.byType(MasteryBurst), findsOneWidget);
      expect(find.text('Savladanost 50% dostignuta'), findsOneWidget);

      // Drain overlay auto-remove timers (max 900 ms)
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('shows mastery MAX burst when reaching 100%', (tester) async {
      // Force portrait layout so options render in single-column (easier to tap)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final quiz = TestQuizProvider();
      final progress = ProgressProvider()..streak = 3;

      // Build up to 96%.
      for (var i = 0; i < 8; i++) {
        quiz.applyMasteryDelta(isCorrect: true);
      }

      await tester.pumpWidget(
        buildTestApp(
          home: buildScreen(),
          providers: [
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.tap(gameButtonByText('4'));
      await tester.pump();

      expect(find.byType(MasteryBurst), findsOneWidget);
      expect(find.text('Savladanost kompletirana'), findsOneWidget);

      // Drain overlay auto-remove timers (max 900 ms)
      await tester.pump(const Duration(seconds: 1));
    });
  });
}

