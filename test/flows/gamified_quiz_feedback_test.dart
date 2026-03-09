import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/screens/home/gamified_quiz_screen.dart';
import 'package:mathlearning/state/progress_provider.dart';
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
void main() {
  setupGlobalMocks();

  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    when(mockSecureStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value'))).thenAnswer((_) async {});
    when(mockSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {});
  });

  bootstrapTests();

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
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Majstorstvo'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('correct answer shows XP pop + streak flame and mastery updates', (tester) async {
      final quiz = TestQuizProvider();
      final progress = ProgressProvider()..streak = 3;

      await tester.pumpWidget(
        buildTestApp(
          home: buildScreen(),
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.tap(gameButtonByText('4'));
      await tester.pump();

      expect(find.text('+20 XP'), findsOneWidget);
      expect(find.byType(StreakFlame), findsOneWidget);
      expect(find.text('12%'), findsOneWidget);
    });

    testWidgets('wrong answer shows localized try-again XP pop', (tester) async {
      final quiz = TestQuizProvider();
      final progress = ProgressProvider()..streak = 3;

      await tester.pumpWidget(
        buildTestApp(
          home: buildScreen(),
          providers: [
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.tap(gameButtonByText('3'));
      await tester.pump();

      expect(find.text('Pokusaj opet'), findsOneWidget);
    });

    testWidgets('shows mastery burst when crossing 50%', (tester) async {
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
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.tap(gameButtonByText('4'));
      await tester.pump();

      expect(find.byType(MasteryBurst), findsOneWidget);
      expect(find.text('Majstorstvo 50%'), findsOneWidget);
    });

    testWidgets('shows mastery MAX burst when reaching 100%', (tester) async {
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
            ChangeNotifierProvider.value(value: quiz),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      await tester.tap(gameButtonByText('4'));
      await tester.pump();

      expect(find.byType(MasteryBurst), findsOneWidget);
      expect(find.text('Majstorstvo MAX!'), findsOneWidget);
    });
  });
}

