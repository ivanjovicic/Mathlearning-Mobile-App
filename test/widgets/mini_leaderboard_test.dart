import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/widgets/mini_leaderboard.dart';

void main() {
  testWidgets('renders rivals list and highlights current user', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniLeaderboard(
            entries: const <RivalLeaderboardEntry>[
              RivalLeaderboardEntry(
                rank: 3,
                userId: 1,
                displayName: 'Mia',
                score: 140,
                streakDays: 6,
              ),
              RivalLeaderboardEntry(
                rank: 4,
                userId: 2,
                displayName: 'Alex',
                score: 132,
                streakDays: 4,
              ),
            ],
            currentUserId: 2,
          ),
        ),
      ),
    );

    expect(find.text('Rivals nearby'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('renders cosmetic badge for rival recent unlocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniLeaderboard(
            entries: const <RivalLeaderboardEntry>[
              RivalLeaderboardEntry(
                rank: 8,
                userId: 8,
                displayName: 'Nova',
                score: 120,
                streakDays: 3,
                cosmeticLoadout: SocialCosmeticLoadout(
                  avatarFrameId: 'frame_olympiad',
                  highlightRarity: CosmeticRarity.epic,
                  recentRareUnlocks: [
                    SocialCosmeticUnlock(
                      itemId: 'effect_neon_number_burst',
                      name: 'Neon Number Burst',
                      rarity: CosmeticRarity.epic,
                    ),
                  ],
                ),
              ),
            ],
            currentUserId: 99,
          ),
        ),
      ),
    );

    expect(find.text('Nova'), findsOneWidget);
    expect(find.text('Epic Find'), findsOneWidget);
  });

  testWidgets('renders retry action on error state', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniLeaderboard(
            entries: const <RivalLeaderboardEntry>[],
            currentUserId: 42,
            errorMessage: 'Network error',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Network error'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });

  testWidgets('renders compact rarity fallback when item name is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniLeaderboard(
            entries: const <RivalLeaderboardEntry>[
              RivalLeaderboardEntry(
                rank: 9,
                userId: 9,
                displayName: 'Echo',
                score: 110,
                streakDays: 2,
                cosmeticLoadout: SocialCosmeticLoadout(
                  trailId: 'trail_unknown_epic',
                  highlightRarity: CosmeticRarity.epic,
                ),
              ),
            ],
            currentUserId: 99,
          ),
        ),
      ),
    );

    expect(find.text('Echo'), findsOneWidget);
    expect(find.text('Epic Trail'), findsOneWidget);
  });

  testWidgets('mini leaderboard target visibility remains compact', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiniLeaderboard(
            entries: const <RivalLeaderboardEntry>[
              RivalLeaderboardEntry(
                rank: 4,
                userId: 2,
                displayName: 'Alex',
                score: 132,
                streakDays: 4,
              ),
            ],
            currentUserId: 2,
            currentUserTarget: const CosmeticTarget(
              targetCosmeticItemId: 'frame_comet',
              targetFragmentsOwned: 4,
              targetFragmentsRequired: 5,
              targetRarity: CosmeticRarity.rare,
              targetItemName: 'Comet Frame',
              targetSlotLabel: 'Frame',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Chasing Comet Frame'), findsOneWidget);
    expect(find.byKey(const Key('cosmetic_target_chip')), findsOneWidget);
  });
}
