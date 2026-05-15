import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/weekly_featured_cosmetic.dart';
import 'package:mathlearning/widgets/weekly_featured_banner.dart';

void main() {
  const itemIds = [
    'effect_nova_trail',
    'frame_comet',
    'effect_neon_number_burst',
    'frame_blue_glow',
  ];

  WeeklyFeaturedCosmeticSet set() => WeeklyFeaturedCosmeticSet(
    rotationId: 'nova-20260511',
    title: 'NOVA WEEK',
    startAt: DateTime(2026, 5, 11),
    endAt: DateTime(2026, 5, 18),
    headlineItemId: 'effect_nova_trail',
    itemIds: itemIds,
    badgeName: 'Nova Week Complete',
    profileFlair: 'Nova Week Complete',
    leaderboardAccentLabel: 'Nova Week Complete',
  );

  testWidgets('countdown displays correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyFeaturedBanner(
            set: set(),
            completed: false,
            now: DateTime(2026, 5, 14),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('weekly_featured_banner')), findsOneWidget);
    expect(find.text('NOVA WEEK'), findsOneWidget);
    expect(find.text('Ends in 4 days'), findsOneWidget);
    expect(find.text('Featured reward set'), findsOneWidget);
  });

  testWidgets('urgency copy changes near end of rotation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyFeaturedBanner(
            set: set(),
            completed: false,
            now: DateTime(2026, 5, 17),
          ),
        ),
      ),
    );

    expect(find.text('Ends tomorrow'), findsOneWidget);
    expect(find.text('Last chance tomorrow'), findsOneWidget);
  });

  testWidgets('featured badge only appears when earned', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyFeaturedBanner(
            set: set(),
            completed: false,
            now: DateTime(2026, 5, 14),
          ),
        ),
      ),
    );

    expect(find.text('Nova Week Complete'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyFeaturedBanner(
            set: set(),
            completed: true,
            now: DateTime(2026, 5, 14),
          ),
        ),
      ),
    );

    expect(find.text('Nova Week Complete'), findsOneWidget);
    expect(
      find.byKey(const Key('weekly_featured_completion_badge')),
      findsOneWidget,
    );
  });
}
