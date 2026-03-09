import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mathlearning/screens/leaderboard_screen.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';
import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/widgets/animated_leaderboard_item.dart';

void main() {
  group('LeaderboardScreen Tests', () {
    late LeaderboardProvider provider;

    setUp(() {
      provider = LeaderboardProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<LeaderboardProvider>.value(
          value: provider,
          child: const LeaderboardScreen(autoLoad: false),
        ),
      );
    }

    testWidgets('displays loading spinner when loading', (WidgetTester tester) async {
      provider.paging.isLoading = true;
      provider.paging.items.clear();
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when there is an error', (WidgetTester tester) async {
      provider.setErrorForTesting(Exception('test')); 
      await tester.pumpWidget(createTestWidget());

      expect(find.text('An error occurred. Please try again.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays empty state message when no data is available', (WidgetTester tester) async {
      provider.paging.isLoading = false;
      provider.setErrorForTesting(null);
      provider.paging.items.clear();
      await tester.pumpWidget(createTestWidget());

      expect(find.text('No leaderboard data available.'), findsOneWidget);
    });

    testWidgets('displays leaderboard items when data is available', (WidgetTester tester) async {
      provider.paging.isLoading = false;
      provider.setErrorForTesting(null);
      provider.paging.items.clear();
      provider.paging.items.addAll([
        LeaderboardItem(rank: 1, userId: 1, displayName: 'Alice', score: 100, streakDays: 10),
        LeaderboardItem(rank: 2, userId: 2, displayName: 'Bob', score: 90, streakDays: 5),
      ]);
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(AnimatedLeaderboardItem), findsNWidgets(2));
    });
  });
}
