import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/widgets/leaderboard_item.dart';

import '../helpers/test_bootstrap.dart';

LeaderboardItem _item({
  SocialCosmeticLoadout? loadout,
  int rank = 4,
  int streakDays = 3,
}) {
  return LeaderboardItem(
    rank: rank,
    userId: 1,
    displayName: 'Zara',
    score: 500,
    streakDays: streakDays,
    cosmeticLoadout: loadout,
  );
}

Widget _wrap(LeaderboardItem item, {bool isCurrentUser = false}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: LeaderboardItemWidget(item: item, isCurrentUser: isCurrentUser),
      ),
    ),
  );
}

Future<void> main() async {
  await bootstrapTests();

  group('LeaderboardItemWidget cosmetic flex chip', () {
    testWidgets(
      'chip appears with real item name when equipped frame present',
      (tester) async {
        final loadout = SocialCosmeticLoadout.fromJson({
          'avatarFrameId': 'frame_comet',
          'recentRareUnlocks': [
            {
              'itemId': 'frame_comet',
              'name': 'Comet Frame',
              'rarity': CosmeticRarity.rare.name,
            },
          ],
        });

        await tester.pumpWidget(_wrap(_item(loadout: loadout)));
        await tester.pump();

        expect(find.text('Comet Frame'), findsOneWidget);
      },
    );

    testWidgets(
      'chip shows rarity fallback when no actual name in recentRareUnlocks',
      (tester) async {
        // No recentRareUnlocks provided — name falls back to _friendlyName().
        final loadout = SocialCosmeticLoadout.fromJson({
          'avatarFrameId': 'frame_gold_unknown',
        });

        await tester.pumpWidget(_wrap(_item(loadout: loadout)));
        await tester.pump();

        // _friendlyName strips "frame_" prefix and title-cases each word.
        expect(find.text('Legendary Frame'), findsOneWidget);
      },
    );

    testWidgets('chip is hidden when cosmeticLoadout is null', (tester) async {
      await tester.pumpWidget(_wrap(_item(loadout: null)));
      await tester.pump();

      // Streak line is present; chip label must not appear.
      expect(find.textContaining('Frame'), findsNothing);
      expect(find.textContaining('Trail'), findsNothing);
      expect(find.textContaining('Look'), findsNothing);
    });

    testWidgets('chip is hidden when loadout has no equipped cosmetics', (
      tester,
    ) async {
      const empty = SocialCosmeticLoadout();
      await tester.pumpWidget(_wrap(_item(loadout: empty)));
      await tester.pump();

      expect(
        empty.hasEquippedCosmetics,
        isFalse,
        reason: 'sanity: loadout must be empty',
      );
      expect(find.textContaining('Frame'), findsNothing);
    });

    testWidgets('no mock cosmetics appear when backend sends no loadout', (
      tester,
    ) async {
      // Simulates an API response that includes no cosmetics field at all.
      final item = LeaderboardItem.fromJson({
        'rank': 5,
        'userId': 99,
        'displayName': 'Ghost',
        'score': 10,
        'streakDays': 0,
      });

      await tester.pumpWidget(_wrap(item));
      await tester.pump();

      expect(
        item.cosmeticLoadout,
        isNull,
        reason: 'backend sent no loadout — must remain null',
      );
      expect(find.textContaining('Frame'), findsNothing);
      expect(find.textContaining('Trail'), findsNothing);
    });

    testWidgets('chip appears for trail slot with friendly name', (
      tester,
    ) async {
      final loadout = SocialCosmeticLoadout.fromJson({
        'trailId': 'trail_nova',
        'recentRareUnlocks': [
          {
            'itemId': 'trail_nova',
            'name': 'Nova Trail',
            'rarity': CosmeticRarity.epic.name,
          },
        ],
      });

      await tester.pumpWidget(_wrap(_item(loadout: loadout)));
      await tester.pump();

      expect(find.text('Nova Trail'), findsOneWidget);
    });

    testWidgets('chip label prioritizes visible frame over rarer trail', (
      tester,
    ) async {
      // Frame comes before trail in equippedItemLabels ordering.
      final loadout = SocialCosmeticLoadout.fromJson({
        'avatarFrameId': 'frame_comet',
        'trailId': 'trail_nova',
        'recentRareUnlocks': [
          {
            'itemId': 'frame_comet',
            'name': 'Comet Frame',
            'rarity': CosmeticRarity.rare.name,
          },
          {
            'itemId': 'trail_nova',
            'name': 'Nova Trail',
            'rarity': CosmeticRarity.epic.name,
          },
        ],
      });

      await tester.pumpWidget(_wrap(_item(loadout: loadout)));
      await tester.pump();

      // Only the first (frame) chip should be in the row — not the trail.
      expect(find.text('Comet Frame'), findsOneWidget);
      expect(find.text('Nova Trail'), findsNothing);
    });
  });
}
