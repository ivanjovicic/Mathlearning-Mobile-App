import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/screens/home_screen.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/coin_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';
import 'package:mathlearning/theme/theme_controller.dart';

import '../helpers/test_app.dart';
import '../helpers/test_bootstrap.dart';
import '../helpers/test_fakes.dart';

void main() {
  bootstrapTests();

  Future<void> pumpHomeReady(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  void useLargeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 3200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('HomeScreen', () {
    testWidgets('shows greeting with trimmed username', (tester) async {
      useLargeViewport(tester);
      final quiz = TestQuizProvider(onGetDailySrsCount: () async => 0);
      final auth = TestAuthProvider(username: '  Mila  ');

      await tester.pumpWidget(
        buildTestApp(
          home: const HomeScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider<CoinProvider>(
              create: (_) => TestCoinProvider(),
            ),
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
          ],
        ),
      );
      await pumpHomeReady(tester);

      expect(find.text('Zdravo, Mila'), findsOneWidget);
    });

    testWidgets('uses fallback student name when username is empty',
        (tester) async {
      useLargeViewport(tester);
      final quiz = TestQuizProvider(onGetDailySrsCount: () async => 0);
      final auth = TestAuthProvider(username: null);

      await tester.pumpWidget(
        buildTestApp(
          home: const HomeScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider<CoinProvider>(
              create: (_) => TestCoinProvider(),
            ),
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
          ],
        ),
      );
      await pumpHomeReady(tester);

      expect(find.text('Zdravo, ucenik'), findsOneWidget);
    });

    testWidgets('shows Daily Review loading subtitle while count is pending',
        (tester) async {
      useLargeViewport(tester);
      final completer = Completer<int>();
      final quiz = TestQuizProvider(onGetDailySrsCount: () => completer.future);

      await tester.pumpWidget(
        buildTestApp(
          home: const HomeScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => TestAuthProvider(),
            ),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider<CoinProvider>(
              create: (_) => TestCoinProvider(),
            ),
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
          ],
        ),
      );
      await pumpHomeReady(tester);

      expect(find.text('Ucitavam dnevni review...'), findsOneWidget);
    });

    testWidgets('disables Daily Review card when count is 0 and shows SnackBar',
        (tester) async {
      useLargeViewport(tester);
      final quiz = TestQuizProvider(onGetDailySrsCount: () async => 0);

      await tester.pumpWidget(
        buildTestApp(
          home: const HomeScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => TestAuthProvider(),
            ),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider<CoinProvider>(
              create: (_) => TestCoinProvider(),
            ),
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
          ],
        ),
      );
      await pumpHomeReady(tester);

      // Flush the daily review count Future.
      await tester.pump();
      await tester.pump();

      expect(find.text('Nema SRS pitanja za danas'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pump();

      expect(find.text('Nema pitanja za danas.'), findsOneWidget);
    });

    testWidgets('shows Daily Review subtitle with count and estimate',
        (tester) async {
      useLargeViewport(tester);
      final quiz = TestQuizProvider(onGetDailySrsCount: () async => 4);

      await tester.pumpWidget(
        buildTestApp(
          home: const HomeScreen(),
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => TestAuthProvider(),
            ),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider<CoinProvider>(
              create: (_) => TestCoinProvider(),
            ),
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
          ],
        ),
      );
      await pumpHomeReady(tester);

      await tester.pump();
      await tester.pump();

      expect(find.text('Danas imas 4 SRS pitanja - ~3 min'), findsOneWidget);
    });

    testWidgets('tapping enabled Daily Review card navigates to route',
        (tester) async {
      useLargeViewport(tester);
      final quiz = TestQuizProvider(onGetDailySrsCount: () async => 2);

      await tester.pumpWidget(
        buildTestApp(
          home: const HomeScreen(),
          routes: {
            '/daily-review': (_) => const Scaffold(
                  body: Center(child: Text('Daily Review Screen')),
                ),
          },
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeController()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => TestAuthProvider(),
            ),
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
            ChangeNotifierProvider<CoinProvider>(
              create: (_) => TestCoinProvider(),
            ),
            ChangeNotifierProvider<QuizProvider>.value(value: quiz),
          ],
        ),
      );
      await pumpHomeReady(tester);

      await tester.pump();
      await tester.pump();

      expect(find.text('Danas imas 2 SRS pitanja - ~2 min'), findsOneWidget);

      await tester.tap(find.text('Danas imas 2 SRS pitanja - ~2 min'));
      await tester.pumpAndSettle();

      expect(find.text('Daily Review Screen'), findsOneWidget);
    });
  });
}

