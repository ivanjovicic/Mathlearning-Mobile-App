import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/daily_return.dart';
import 'package:mathlearning/widgets/daily_return_panel.dart';

void main() {
  testWidgets(
    'daily return panel shows honest streak pressure and weekly progress',
    (tester) async {
      final state = DailyReturnState(
        userId: 'user-1',
        dateKey: '2026-05-15',
        currentStreak: 6,
        practicedToday: false,
        streakFreezeCount: 1,
        streakMultiplier: 1.25,
        chestQualityLabel: 'Rare streak chest',
        streakAtRisk: true,
        weeklyGoals: const [
          DailyReturnWeeklyGoal(
            id: 'weekly_daily_runs',
            title: '5 Daily Runs',
            progress: 3,
            target: 5,
          ),
        ],
        modifiers: const [
          DailyReturnModifier(type: DailyReturnModifierType.doubleFragmentDay),
        ],
        reachedMilestones: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DailyReturnPanel(state: state)),
        ),
      );

      expect(find.byKey(const Key('daily_return_panel')), findsOneWidget);
      expect(find.text('1 run saves your streak'), findsOneWidget);
      expect(find.text('2x fragments'), findsOneWidget);
      expect(find.text('3/5'), findsOneWidget);
      expect(
        find.byKey(const Key('daily_return_streak_flame')),
        findsOneWidget,
      );
    },
  );
}
