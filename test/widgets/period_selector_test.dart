import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/widgets/period_selector.dart';

void main() {
  testWidgets('switches between leaderboard periods', (tester) async {
    LeaderboardPeriod? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PeriodSelector(
            value: LeaderboardPeriod.week,
            onChanged: (period) => selected = period,
          ),
        ),
      ),
    );

    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Month'), findsOneWidget);
    expect(find.text('All-time'), findsOneWidget);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();

    expect(selected, LeaderboardPeriod.month);
  });
}
