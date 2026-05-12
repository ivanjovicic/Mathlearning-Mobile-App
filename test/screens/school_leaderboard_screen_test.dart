import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/screens/school_leaderboard_screen.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';

import '../helpers/test_fakes.dart';

void main() {
  testWidgets('renders school leaderboard entries', (tester) async {
    final provider = TestLeaderboardProvider(
      schoolItems: const <SchoolLeaderboardEntry>[
        SchoolLeaderboardEntry(
          rank: 1,
          schoolId: 10,
          schoolName: 'Belgrade Math Gymnasium',
          totalScore: 9800,
          members: 120,
          badgeLabel: 'Gold League',
        ),
        SchoolLeaderboardEntry(
          rank: 2,
          schoolId: 11,
          schoolName: 'Novi Sad Academy',
          totalScore: 9450,
          members: 98,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LeaderboardProvider>.value(
          value: provider,
          child: const SchoolLeaderboardScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Belgrade Math Gymnasium'), findsOneWidget);
    expect(
      find.textContaining('Your school: Belgrade Math Gymnasium'),
      findsOneWidget,
    );
    expect(find.text('9800'), findsOneWidget);
    expect(find.textContaining('9800 total score'), findsOneWidget);
    expect(find.text('Gold League'), findsOneWidget);
    // No mock avatars — empty topAvatars shows the honest fallback text.
    expect(find.text('No avatar flex yet'), findsWidgets);
  });

  testWidgets('changing period reloads school leaderboard', (tester) async {
    final provider = TestLeaderboardProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LeaderboardProvider>.value(
          value: provider,
          child: const SchoolLeaderboardScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('All-time'));
    await tester.pump();

    expect(provider.currentPeriod, LeaderboardPeriod.allTime);
    expect(provider.reloadSchoolsCalls, greaterThan(0));
  });
}
