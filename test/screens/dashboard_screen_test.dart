import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/screens/dashboard_screen.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/badge_provider.dart';
import 'package:mathlearning/state/coin_provider.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';

import '../helpers/test_app.dart';
import '../helpers/test_bootstrap.dart';
import '../helpers/test_fakes.dart';

class _TestDashboardProgressProvider extends ProgressProvider {
  _TestDashboardProgressProvider() {
    level = 1;
    xp = 12;
    xpToNextLevel = 100;
    streak = 3;
    totalAttempts = 6;
    accuracy = 83.33;
    topics = <TopicProgress>[
      TopicProgress(
        name: 'Osnovne operacije',
        requiredLevel: 1,
        unlocked: true,
        topicId: 1,
      ),
      TopicProgress(
        name: 'Razlomci',
        requiredLevel: 1,
        unlocked: true,
        topicId: 2,
      ),
    ];
  }

  @override
  Future<void> loadProgress({bool forceRefresh = false}) async {}

  @override
  Future<void> loadTopics({bool forceRefresh = false}) async {}

  @override
  Future<({int freezesUsed, bool streakBroken})> rollDailyStreakIfNeeded({
    DateTime? now,
  }) async {
    return (freezesUsed: 0, streakBroken: false);
  }
}

Future<void> main() async {
  await bootstrapTests();

  testWidgets('renders without sliver layout exceptions on medium width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(500, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final progress = _TestDashboardProgressProvider();

    await tester.pumpWidget(
      buildTestApp(
        home: const DashboardScreen(),
        providers: [
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => TestAuthProvider(username: 'Admin', userId: '1'),
          ),
          ChangeNotifierProvider<ProgressProvider>.value(value: progress),
          ChangeNotifierProvider<CoinProvider>(
            create: (_) => TestCoinProvider(),
          ),
          ChangeNotifierProvider<QuizProvider>(
            create: (_) => TestQuizProvider(onGetDailySrsCount: () async => 0),
          ),
          ChangeNotifierProvider<LeaderboardProvider>(
            create: (_) => TestLeaderboardProvider(),
          ),
          ChangeNotifierProvider<BadgeProvider>(
            create: (_) => BadgeProvider(progress),
          ),
        ],
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Zdravo'), findsOneWidget);
  });
}
