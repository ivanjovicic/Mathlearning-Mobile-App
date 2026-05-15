import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/user_profile.dart';
import 'package:mathlearning/screens/user_profile_screen.dart';
import 'package:mathlearning/widgets/social_cosmetic_avatar.dart';

void main() {
  testWidgets('shows user profile with honest empty cosmetic state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(userId: '3', profileLoader: (_) async => null),
      ),
    );
    await tester.pump();

    expect(find.text('User 3'), findsOneWidget);
    expect(find.text('Recent unlocks'), findsOneWidget);
    expect(find.text('No cosmetic unlocks yet.'), findsOneWidget);
    expect(find.text('No cosmetics equipped yet'), findsOneWidget);
    expect(find.byType(RecentUnlocksStrip), findsOneWidget);
  });

  testWidgets('shows real equipped cosmetic names from API profile', (
    tester,
  ) async {
    final now = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          userId: '7',
          profileLoader: (_) async => UserProfile.fromJson({
            'id': '7',
            'username': 'nova',
            'displayName': 'Nova',
            'email': 'nova@example.com',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'cosmeticLoadout': {
              'avatarFrameId': 'frame_comet',
              'trailId': 'trail_nova',
              'recentRareUnlocks': [
                {
                  'itemId': 'frame_comet',
                  'name': 'Comet Frame',
                  'rarity': CosmeticRarity.rare.name,
                },
              ],
            },
          }),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nova'), findsWidgets);
    expect(find.text('Comet Frame'), findsWidgets);
    expect(find.text('Rare Find'), findsOneWidget);
    expect(find.text('No cosmetics equipped yet'), findsNothing);
  });

  testWidgets('does not render fake LineChart widgets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(userId: '1', profileLoader: (_) async => null),
      ),
    );
    await tester.pump();

    // fl_chart LineChart must not appear anywhere in the tree.
    expect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == 'LineChart'),
      findsNothing,
    );
    // The old fake section headings must not appear.
    expect(find.text('XP Progress Chart'), findsNothing);
  });

  testWidgets('empty history sections collapse into one honest note', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(userId: '5', profileLoader: (_) async => null),
      ),
    );
    await tester.pump();

    expect(find.text('XP History'), findsNothing);
    expect(find.text('Rank History'), findsNothing);
    expect(find.text('No XP history yet.'), findsNothing);
    expect(find.text('No rank history yet.'), findsNothing);
    expect(find.text('More stats coming soon.'), findsOneWidget);
  });

  testWidgets('stats section renders real XP and level from UserProfile', (
    tester,
  ) async {
    final now = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          userId: '9',
          profileLoader: (_) async => UserProfile.fromJson({
            'id': '9',
            'username': 'atlas',
            'displayName': 'Atlas',
            'email': 'atlas@example.com',
            'xp': 4200,
            'level': 17,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('4200'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    expect(find.text('XP'), findsOneWidget);
    expect(find.text('Level'), findsOneWidget);
  });

  testWidgets('missing xp and level render as not available', (tester) async {
    final now = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          userId: '10',
          profileLoader: (_) async => UserProfile.fromJson({
            'id': '10',
            'username': 'quiet',
            'displayName': 'Quiet',
            'email': 'quiet@example.com',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          }),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('XP'), findsOneWidget);
    expect(find.text('Level'), findsOneWidget);
    expect(find.text('Not available'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('stats section shows equipped and unlock counts when available', (
    tester,
  ) async {
    final now = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: UserProfileScreen(
          userId: '11',
          profileLoader: (_) async => UserProfile.fromJson({
            'id': '11',
            'username': 'orion',
            'displayName': 'Orion',
            'email': 'orion@example.com',
            'xp': 800,
            'level': 5,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'cosmeticLoadout': {
              'avatarFrameId': 'frame_gold_laurel',
              'recentRareUnlocks': [
                {
                  'itemId': 'frame_gold_laurel',
                  'name': 'Gold Laurel',
                  'rarity': CosmeticRarity.legendary.name,
                },
                {
                  'itemId': 'trail_comet',
                  'name': 'Comet Trail',
                  'rarity': CosmeticRarity.epic.name,
                },
              ],
            },
          }),
        ),
      ),
    );
    await tester.pump();

    // Equipped count chip: 1 equipped slot (avatarFrameId only)
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Equipped'), findsOneWidget);
    // Unlock count chip: 2 recent rare unlocks
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Unlocks'), findsOneWidget);
  });
}
