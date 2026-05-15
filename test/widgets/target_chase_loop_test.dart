// Tests for the "One More Run" retention pass:
//   1. TargetCosmeticChaseCard shows no-target prompt when target is null.
//   2. TargetCosmeticChaseCard shows 5-segment bonus progress pips.
//   3. LeaderboardItemWidget shows CosmeticTargetChip for current user.
//   4. LeaderboardItemWidget does NOT show chip for other users.
//   5. TargetFragmentFoundBanner shows "BONUS FRAGMENT EARNED!" for bonus events.
//   6. BonusProgressRow shows X/5 progress text and pip key.
//   7. BonusProgressRow always renders (not hidden when bonusProgressAwarded > 0).
//   8. RewardFlyToTarget.play() returns false (safe) when target key not mounted.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/widgets/leaderboard_item.dart';
import 'package:mathlearning/widgets/reward_fly_to_target.dart';
import 'package:mathlearning/widgets/target_cosmetic_chase_card.dart';
import 'package:mathlearning/widgets/target_fragment_reveal.dart';

import '../helpers/test_bootstrap.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _target = CosmeticTarget(
  targetCosmeticItemId: 'frame_comet',
  targetFragmentsOwned: 2,
  targetFragmentsRequired: 5,
  targetRarity: CosmeticRarity.rare,
  targetItemName: 'Comet Frame',
  targetSlotLabel: 'Frame',
);

const _targetWithProgress = CosmeticTarget(
  targetCosmeticItemId: 'frame_comet',
  targetFragmentsOwned: 2,
  targetFragmentsRequired: 5,
  targetRarity: CosmeticRarity.rare,
  targetItemName: 'Comet Frame',
  targetSlotLabel: 'Frame',
  bonusProgress: 3,
);

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

LeaderboardItem _leaderboardItem({SocialCosmeticLoadout? loadout}) {
  return LeaderboardItem(
    rank: 3,
    userId: 42,
    displayName: 'Alex',
    score: 800,
    streakDays: 5,
    cosmeticLoadout: loadout,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  bootstrapTests();

  group('TargetCosmeticChaseCard no-target prompt', () {
    testWidgets('shows prompt when no target exists', (tester) async {
      await tester.pumpWidget(_wrap(const TargetCosmeticChaseCard()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no_target_prompt')), findsOneWidget);
      expect(find.text('Pick your next chase'), findsOneWidget);
    });

    testWidgets('shows compact prompt in compact mode', (tester) async {
      await tester.pumpWidget(
        _wrap(const TargetCosmeticChaseCard(compact: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no_target_prompt')), findsOneWidget);
      // Compact mode: long description line is hidden.
      expect(
        find.text('Tap any leaderboard cosmetic to start chasing it.'),
        findsNothing,
      );
    });

    testWidgets('does NOT show prompt when target exists', (tester) async {
      await tester.pumpWidget(
        _wrap(const TargetCosmeticChaseCard(target: _target)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no_target_prompt')), findsNothing);
      expect(find.byKey(const Key('daily_run_target_header')), findsOneWidget);
    });
  });

  group('TargetCosmeticChaseCard bonus progress section', () {
    testWidgets('shows pip row when bonusProgress > 0', (tester) async {
      await tester.pumpWidget(
        _wrap(const TargetCosmeticChaseCard(target: _targetWithProgress)),
      );
      await tester.pumpAndSettle();

      // 5 pips rendered
      for (var i = 0; i < CosmeticTarget.kBonusProgressMax; i++) {
        expect(find.byKey(ValueKey('pip_$i')), findsOneWidget);
      }
      // X/5 label
      expect(
        find.textContaining('3/${CosmeticTarget.kBonusProgressMax}'),
        findsOneWidget,
      );
    });

    testWidgets('does NOT show pip row when bonusProgress is 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const TargetCosmeticChaseCard(target: _target)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pip_0')), findsNothing);
    });
  });

  group('LeaderboardItemWidget CosmeticTargetChip', () {
    testWidgets('shows CosmeticTargetChip for current user with target', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardItemWidget(
                item: _leaderboardItem(),
                isCurrentUser: true,
                currentUserTarget: _target,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('cosmetic_target_chip')), findsOneWidget);
      expect(find.textContaining('Chasing Comet Frame'), findsOneWidget);
    });

    testWidgets('does NOT show CosmeticTargetChip for other users', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardItemWidget(
                item: _leaderboardItem(),
                isCurrentUser: false,
                currentUserTarget: _target,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('cosmetic_target_chip')), findsNothing);
    });

    testWidgets('does NOT show CosmeticTargetChip when target is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LeaderboardItemWidget(
                item: _leaderboardItem(),
                isCurrentUser: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('cosmetic_target_chip')), findsNothing);
    });

    testWidgets(
      'shows both CosmeticFlexChip AND CosmeticTargetChip when applicable',
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

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LeaderboardItemWidget(
                  item: _leaderboardItem(loadout: loadout),
                  isCurrentUser: true,
                  currentUserTarget: const CosmeticTarget(
                    targetCosmeticItemId: 'trail_nova',
                    targetFragmentsOwned: 1,
                    targetFragmentsRequired: 5,
                    targetRarity: CosmeticRarity.epic,
                    targetItemName: 'Nova Trail',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Comet Frame'), findsOneWidget);
        expect(find.byKey(const Key('cosmetic_target_chip')), findsOneWidget);
        expect(find.textContaining('Chasing Nova Trail'), findsOneWidget);
      },
    );
  });

  group('TargetFragmentFoundBanner heading', () {
    testWidgets('shows TARGET FRAGMENT FOUND for direct drop', (tester) async {
      const event = CosmeticTargetProgressEvent(
        target: _target,
        previousFragments: 2,
        currentFragments: 3,
        targetFragmentFound: true,
      );

      await tester.pumpWidget(_wrap(TargetFragmentFoundBanner(event: event)));
      await tester.pumpAndSettle();

      expect(find.text('TARGET FRAGMENT FOUND!'), findsOneWidget);
      expect(find.text('BONUS FRAGMENT EARNED!'), findsNothing);
    });

    testWidgets(
      'shows BONUS FRAGMENT EARNED for bonus progress threshold event',
      (tester) async {
        const event = CosmeticTargetProgressEvent(
          target: _target,
          previousFragments: 2,
          currentFragments: 3,
          targetFragmentFound: true,
          bonusFragmentEarned: true,
          bonusProgressAwarded: 1,
        );

        await tester.pumpWidget(_wrap(TargetFragmentFoundBanner(event: event)));
        await tester.pumpAndSettle();

        expect(find.text('BONUS FRAGMENT EARNED!'), findsOneWidget);
        expect(find.text('TARGET FRAGMENT FOUND!'), findsNothing);
      },
    );
  });

  group('BonusProgressRow', () {
    testWidgets('shows X/5 progress text and pip container', (tester) async {
      const event = CosmeticTargetProgressEvent(
        target: _targetWithProgress,
        previousFragments: 2,
        currentFragments: 2,
        targetFragmentFound: false,
        bonusProgressAwarded: 1,
      );

      await tester.pumpWidget(_wrap(BonusProgressRow(event: event)));
      await tester.pumpAndSettle();

      // The bonus_progress_row container is present
      expect(find.byKey(const Key('bonus_progress_row')), findsOneWidget);
      // Shows +1 awarded text
      expect(find.textContaining('+1 Bonus Fragment Progress'), findsOneWidget);
      // Shows X/5
      expect(
        find.textContaining('3/${CosmeticTarget.kBonusProgressMax}'),
        findsOneWidget,
      );
    });

    testWidgets('always renders even when bonusProgressAwarded is 0', (
      tester,
    ) async {
      const event = CosmeticTargetProgressEvent(
        target: _targetWithProgress,
        previousFragments: 2,
        currentFragments: 2,
        targetFragmentFound: false,
        bonusProgressAwarded: 0,
      );

      await tester.pumpWidget(_wrap(BonusProgressRow(event: event)));
      await tester.pumpAndSettle();

      // Row is always visible â€” no run should end silently.
      expect(find.byKey(const Key('bonus_progress_row')), findsOneWidget);
    });
  });

  group('RewardFlyToTarget safe fallback', () {
    testWidgets('play() shows target impact pulse near arrival', (
      tester,
    ) async {
      final sourceKey = GlobalKey(debugLabel: 'source');
      final targetKey = GlobalKey(debugLabel: 'target');
      Future<bool>? flight;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Stack(
                  children: [
                    Positioned(
                      left: 24,
                      top: 80,
                      child: SizedBox(
                        key: sourceKey,
                        width: 32,
                        height: 32,
                        child: const ColoredBox(color: Colors.blue),
                      ),
                    ),
                    Positioned(
                      left: 220,
                      top: 260,
                      child: SizedBox(
                        key: targetKey,
                        width: 44,
                        height: 44,
                        child: const ColoredBox(color: Colors.purple),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        flight = RewardFlyToTarget.play(
                          context,
                          sourceKey: sourceKey,
                          targetKey: targetKey,
                          color: Colors.purple,
                          icon: Icons.star,
                          debugLabel: 'impact_test',
                          duration: const Duration(milliseconds: 600),
                          particleCount: 8,
                        );
                      },
                      child: const Text('Fire'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Fire'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 520));

      expect(
        find.byKey(const Key('reward_target_impact_pulse')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 240));
      expect(await flight, isTrue);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('play() returns false when target key is not mounted', (
      tester,
    ) async {
      final unmountedKey = GlobalKey(debugLabel: 'unmounted_target');

      late bool result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await RewardFlyToTarget.play(
                    context,
                    sourceKey: unmountedKey,
                    targetKey: unmountedKey,
                    color: Colors.purple,
                    icon: Icons.star,
                    debugLabel: 'test',
                  );
                },
                child: const Text('Fire'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Fire'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
