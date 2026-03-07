import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  Future<void> loadGlobal(String range) async {}

  @override
  Future<void> loadFriends(String range) async {}
}

void main() {
  bootstrapTests();

  group('LeaderboardScreen', () {
    testWidgets('shows loading indicator when provider isLoading is true',
        (tester) async {
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

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state with RefreshIndicator when list is empty',
        (tester) async {
      final leaderboard = _NoopLeaderboardProvider();
      leaderboard.pagingFor(LeaderboardScope.global).isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LeaderboardProvider>.value(
            value: leaderboard,
            child: const LeaderboardScreen(),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('Nema podataka.'), findsOneWidget);
    });

    testWidgets('renders rows and highlights current user with "Ti"',
        (tester) async {
      final items = [
        LeaderboardItem(
          rank: 1,
          userId: 1,
          displayName: 'Top Player',
          score: 300,
          streakDays: 12,
        ),
        LeaderboardItem(
          rank: 5,
          userId: 42,
          displayName: 'Alex',
          score: 123,
          streakDays: 7,
        ),
      ];

      final leaderboard = TestLeaderboardProvider(globalItems: items);
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

      // Let initState post-frame loads run.
      await tester.pump();

      expect(find.text('Alex'), findsOneWidget);
      expect(find.text('Ti'), findsOneWidget);
      expect(find.text('123 XP'), findsOneWidget);
    });

    testWidgets('changing range reloads current scope with new range', (tester) async {
      final leaderboard = TestLeaderboardProvider(
        globalItems: const [],
        friendsItems: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LeaderboardProvider>.value(
            value: leaderboard,
            child: const LeaderboardScreen(),
          ),
        ),
      );

      await tester.pump();

      // Open dropdown and select "Ukupno" (allTime).
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pump();
      await tester.tap(find.text('Ukupno').last);
      await tester.pump();

      expect(leaderboard.lastReloadScope, LeaderboardScope.global);
      expect(leaderboard.lastReloadRange, 'allTime');
      expect(leaderboard.reloadScopeCalls, greaterThan(0));
    });
  });
}
