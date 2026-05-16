import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/cosmetic_fragment_progress.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/services/cosmetics_service.dart';
import 'package:mathlearning/services/new_look_badge_service.dart';
import 'package:mathlearning/state/cosmetic_target_provider.dart';
import 'package:mathlearning/widgets/animated_leaderboard_item.dart';
import 'package:mathlearning/widgets/target_fragment_reveal.dart';

import '../helpers/test_bootstrap.dart';

const _target = CosmeticTarget(
  targetCosmeticItemId: 'frame_comet',
  targetFragmentsOwned: 2,
  targetFragmentsRequired: 5,
  targetRarity: CosmeticRarity.rare,
  targetItemName: 'Comet Frame',
  targetSlotLabel: 'Frame',
);

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() async {
  await bootstrapTests();

  group('Target chase regression', () {
    testWidgets(
      'set target and non-target runs fill bonus progress without fake fragments',
      (tester) async {
        final catalog = CosmeticsService.instance.getCatalog();
        final targetItem = catalog.firstWhere((entry) => entry.id == 'frame_comet');
        final nonTarget = catalog.firstWhere(
          (entry) => entry.id == 'effect_nova_trail',
        );
        final provider = CosmeticTargetProvider();
        await provider.load(userId: 'user-1');

        await provider.setTargetFromCatalogItem(
          item: targetItem,
          progress: CosmeticFragmentProgress(
            itemId: 'frame_comet',
            collectedFragments: 2,
            requiredFragments: 5,
            updatedAt: DateTime(2026),
          ),
        );

        final first = await provider.applyDailyRunGrant(
          DailyRunCosmeticGrantResult(
            item: nonTarget,
            progress: CosmeticFragmentProgress(
              itemId: 'effect_nova_trail',
              collectedFragments: 1,
              requiredFragments: 5,
              updatedAt: DateTime(2026, 1, 2),
            ),
            previousFragments: 0,
            didUnlock: false,
          ),
        );

        expect(first?.targetFragmentFound, isFalse);
        expect(first?.bonusProgressAwarded, 1);
        expect(provider.target?.targetFragmentsOwned, 2);
        expect(provider.target?.bonusProgress, 1);

        for (var i = 1; i < 5; i++) {
          final event = await provider.applyDailyRunGrant(
            DailyRunCosmeticGrantResult(
              item: nonTarget,
              progress: CosmeticFragmentProgress(
                itemId: 'effect_nova_trail',
                collectedFragments: i + 1,
                requiredFragments: 5,
                updatedAt: DateTime(2026, 1, 2 + i),
              ),
              previousFragments: i,
              didUnlock: false,
            ),
          );

          if (i < 4) {
            expect(event?.bonusFragmentEarned, isFalse);
          }
        }

        expect(provider.target?.targetFragmentsOwned, 3);
        expect(provider.target?.bonusProgress, 0);
      },
    );

    testWidgets('bonus fragment ceremony stays visible for bonus events', (
      tester,
    ) async {
      const event = CosmeticTargetProgressEvent(
        target: _target,
        previousFragments: 2,
        currentFragments: 3,
        targetFragmentFound: true,
        bonusProgressAwarded: 1,
        bonusFragmentEarned: true,
      );

      await tester.pumpWidget(_wrap(TargetFragmentFoundBanner(event: event)));
      await tester.pumpAndSettle();

      expect(find.text('BONUS FRAGMENT EARNED!'), findsOneWidget);
    });

    testWidgets('unlocked target cosmetic can be equipped after grant', (
      tester,
    ) async {
      DailyRunCosmeticGrantResult grant =
          await CosmeticsService.instance.grantDailyRunFragment(
            fragmentName: 'Comet Frame',
          );
      for (var i = 1; i < CosmeticsService.dailyRunRequiredFragments; i++) {
        grant = await CosmeticsService.instance.grantDailyRunFragment(
          fragmentName: 'Comet Frame',
        );
      }

      expect(grant.didUnlock, isTrue);
      expect(grant.unlockedCosmetic, isNotNull);
      expect(
        await CosmeticsService.instance.ownsItemLocally(grant.item.id),
        isTrue,
      );
    });

    testWidgets('local cosmetics service can unlock and equip a target cosmetic', (
      tester,
    ) async {
      final grant = await CosmeticsService.instance.grantDailyRunFragment(
        fragmentName: 'Comet Frame',
      );
      for (var i = 1; i < CosmeticsService.dailyRunRequiredFragments; i++) {
        await CosmeticsService.instance.grantDailyRunFragment(
          fragmentName: 'Comet Frame',
        );
      }

      expect(grant.item.id, 'frame_comet');
      expect(
        await CosmeticsService.instance.ownsItemLocally('frame_comet'),
        isTrue,
      );

      await CosmeticsService.instance.equipItem('Comet Frame');
      expect(await NewLookBadgeService.instance.isActive(), isTrue);
    });
  });

  group('Leaderboard cosmetics regression', () {
    testWidgets('null backend loadout renders no fake cosmetics', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AnimatedLeaderboardItem(
            item: LeaderboardItem(
              rank: 3,
              userId: 7,
              displayName: 'Nova',
              score: 900,
              streakDays: 8,
              cosmeticLoadout: null,
            ),
          ),
        ),
      );

      expect(find.text('Nova'), findsOneWidget);
      expect(find.byKey(const Key('leaderboard_cosmetic_accent')), findsNothing);
      expect(find.textContaining('Comet Frame'), findsNothing);
    });

    testWidgets('real loadout renders a cosmetic chip', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnimatedLeaderboardItem(
            item: LeaderboardItem(
              rank: 3,
              userId: 7,
              displayName: 'Nova',
              score: 900,
              streakDays: 8,
              cosmeticLoadout: SocialCosmeticLoadout(
                avatarFrameId: 'frame_comet',
                recentRareUnlocks: [
                  SocialCosmeticUnlock(
                    itemId: 'frame_comet',
                    name: 'Comet Frame',
                    rarity: CosmeticRarity.rare,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Comet Frame'), findsOneWidget);
      expect(find.byKey(const Key('leaderboard_cosmetic_accent')), findsOneWidget);
    });

    testWidgets('quick chase opens the correct sheet', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AnimatedLeaderboardItem(
            item: LeaderboardItem(
              rank: 2,
              userId: 9,
              displayName: 'Cosmo',
              score: 1200,
              streakDays: 9,
              cosmeticLoadout: SocialCosmeticLoadout(
                avatarFrameId: 'frame_comet',
                recentRareUnlocks: [
                  SocialCosmeticUnlock(
                    itemId: 'frame_comet',
                    name: 'Comet Frame',
                    rarity: CosmeticRarity.rare,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Comet Frame'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('quick_chase_set_target_button')), findsOneWidget);
      expect(find.byKey(const Key('quick_chase_try_on_button')), findsOneWidget);
    });
  });
}
