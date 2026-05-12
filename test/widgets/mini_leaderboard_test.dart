import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
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
                  recentUnlocks: [
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
    expect(find.text('EPIC'), findsOneWidget);
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
}
