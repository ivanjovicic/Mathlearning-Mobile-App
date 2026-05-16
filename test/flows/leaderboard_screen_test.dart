import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_shimmer/flutter_shimmer.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/screens/leaderboard_screen.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';

import '../helpers/test_bootstrap.dart';
import '../helpers/test_fakes.dart';

class _NoopLeaderboardProvider extends LeaderboardProvider {
  _NoopLeaderboardProvider();

  @override
  Future<void> ensureUsersLoaded() async {}

  @override
  Future<void> loadGlobal([LeaderboardPeriod? period]) async {}

  @override
  Future<void> loadFriends([LeaderboardPeriod? period]) async {}
}

Future<void> main() async {
  await bootstrapTests();

  group('LeaderboardScreen', () {
    testWidgets('shows loading indicator when provider isLoading is true', (
      tester,
    ) async {
      final leaderboard = _NoopLeaderboardProvider();
      leaderboard.pagingFor(LeaderboardScope.global).isLoading = true;
      final auth = TestAuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LeaderboardProvider>.value(
            value: leaderboard,
            child: ChangeNotifierProvider<AuthProvider>.value(
              value: auth,
              child: const LeaderboardScreen(),
            ),
          ),
        ),
      );

      expect(find.byType(ListTileShimmer), findsWidgets);
    });

    testWidgets('shows empty state with RefreshIndicator when list is empty', (
      tester,
    ) async {
      final leaderboard = _NoopLeaderboardProvider();
      leaderboard.pagingFor(LeaderboardScope.global).isLoading = false;
      final auth = TestAuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LeaderboardProvider>.value(
            value: leaderboard,
            child: ChangeNotifierProvider<AuthProvider>.value(
              value: auth,
              child: const LeaderboardScreen(),
            ),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('No leaderboard data yet.'), findsOneWidget);
    });

    testWidgets('renders rows, highlights current user and shows rivals', (
      tester,
    ) async {
      final items = <LeaderboardItem>[
        const LeaderboardItem(
          rank: 1,
          userId: 1,
          displayName: 'Top Player',
          score: 300,
          streakDays: 12,
        ),
        const LeaderboardItem(
          rank: 5,
          userId: 42,
          displayName: 'Alex',
          score: 123,
          streakDays: 7,
        ),
      ];

      final rivals = <RivalLeaderboardEntry>[
        const RivalLeaderboardEntry(
          rank: 3,
          userId: 30,
          displayName: 'Mia',
          score: 145,
          streakDays: 4,
        ),
        const RivalLeaderboardEntry(
          rank: 4,
          userId: 31,
          displayName: 'Noah',
          score: 132,
          streakDays: 5,
        ),
        const RivalLeaderboardEntry(
          rank: 5,
          userId: 42,
          displayName: 'Alex',
          score: 123,
          streakDays: 7,
        ),
      ];

      final leaderboard = TestLeaderboardProvider(
        globalItems: items,
        rivalsItems: rivals,
      );
      final auth = TestAuthProvider(userId: '42');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LeaderboardProvider>.value(
            value: leaderboard,
            child: ChangeNotifierProvider<AuthProvider>.value(
              value: auth,
              child: const LeaderboardScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Alex'), findsNWidgets(2));
      expect(find.text('Ti'), findsOneWidget);
      expect(find.text('Rivals nearby'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('changing period reloads current board and updates provider', (
      tester,
    ) async {
      final leaderboard = TestLeaderboardProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LeaderboardProvider>.value(
            value: leaderboard,
            child: const LeaderboardScreen(autoLoad: false),
          ),
        ),
      );

      await tester.tap(find.text('Month'));
      await tester.pump();

      expect(leaderboard.currentPeriod, LeaderboardPeriod.month);
      expect(leaderboard.lastReloadScope, LeaderboardScope.global);
      expect(leaderboard.lastReloadPeriod, LeaderboardPeriod.month);
    });
  });
}
