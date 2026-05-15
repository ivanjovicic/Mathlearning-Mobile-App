import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/state/avatar_provider.dart';
import 'package:mathlearning/state/cosmetic_preview_provider.dart';
import 'package:mathlearning/widgets/animated_leaderboard_item.dart';

Widget _wrap(
  LeaderboardItem item, {
  bool isCurrentUser = false,
  CosmeticTarget? currentUserTarget,
  String? weeklyFeaturedCompletionLabel,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AnimatedLeaderboardItem(
        item: item,
        isCurrentUser: isCurrentUser,
        subtitle: '${item.score} XP',
        currentUserTarget: currentUserTarget,
        weeklyFeaturedCompletionLabel: weeklyFeaturedCompletionLabel,
      ),
    ),
  );
}

Widget _wrapWithPreviewProviders(
  LeaderboardItem item, {
  required AvatarProvider avatarProvider,
  required CosmeticPreviewProvider previewProvider,
  bool isCurrentUser = false,
  CosmeticTarget? currentUserTarget,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AvatarProvider>.value(value: avatarProvider),
      ChangeNotifierProvider<CosmeticPreviewProvider>.value(
        value: previewProvider,
      ),
    ],
    child: _wrap(
      item,
      isCurrentUser: isCurrentUser,
      currentUserTarget: currentUserTarget,
    ),
  );
}

void main() {
  testWidgets('animated leaderboard shows cosmetic chip with real loadout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LeaderboardItem(
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
    );

    expect(find.text('Nova'), findsOneWidget);
    expect(find.text('Comet Frame'), findsOneWidget);
    expect(
      find.byKey(const Key('leaderboard_cosmetic_accent')),
      findsOneWidget,
    );
  });

  testWidgets('animated leaderboard hides chip for empty loadout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LeaderboardItem(
          rank: 4,
          userId: 8,
          displayName: 'Plain',
          score: 500,
          streakDays: 1,
          cosmeticLoadout: SocialCosmeticLoadout(),
        ),
      ),
    );

    expect(find.text('Plain'), findsOneWidget);
    expect(find.textContaining('Look'), findsNothing);
    expect(find.textContaining('Frame'), findsNothing);
    expect(find.byKey(const Key('leaderboard_cosmetic_accent')), findsNothing);
  });

  testWidgets('try-on preview works from leaderboard quick chase flow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final avatarProvider = AvatarProvider();
    final previewProvider = CosmeticPreviewProvider()..configureUser('me');

    await tester.pumpWidget(
      _wrapWithPreviewProviders(
        const LeaderboardItem(
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
        avatarProvider: avatarProvider,
        previewProvider: previewProvider,
      ),
    );

    await tester.tap(find.text('Comet Frame'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('quick_chase_set_target_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('quick_chase_try_on_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick_chase_try_on_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('cosmetic_try_on_panel')), findsOneWidget);
    expect(find.byKey(const Key('previewing_pill')), findsOneWidget);
    expect(find.byKey(const Key('back_to_my_look_button')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('back_to_my_look_button')));
    await tester.tap(find.byKey(const Key('back_to_my_look_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('cosmetic_try_on_panel')), findsNothing);
  });

  testWidgets('animated leaderboard shows current user target chase', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const LeaderboardItem(
          rank: 5,
          userId: 1,
          displayName: 'Alex',
          score: 700,
          streakDays: 5,
        ),
        isCurrentUser: true,
        currentUserTarget: const CosmeticTarget(
          targetCosmeticItemId: 'frame_comet',
          targetFragmentsOwned: 3,
          targetFragmentsRequired: 5,
          targetRarity: CosmeticRarity.rare,
          targetItemName: 'Comet Frame',
          targetSlotLabel: 'Frame',
        ),
      ),
    );

    expect(find.text('Chasing Comet Frame'), findsOneWidget);
    expect(find.byKey(const Key('cosmetic_target_chip')), findsOneWidget);
  });

  testWidgets(
    'weekly featured badge appears only when earned for current user',
    (tester) async {
      const item = LeaderboardItem(
        rank: 6,
        userId: 1,
        displayName: 'Alex',
        score: 640,
        streakDays: 5,
      );

      await tester.pumpWidget(_wrap(item, isCurrentUser: true));
      expect(find.text('Nova Week Complete'), findsNothing);

      await tester.pumpWidget(
        _wrap(
          item,
          isCurrentUser: true,
          weeklyFeaturedCompletionLabel: 'Nova Week Complete',
        ),
      );

      expect(find.text('Nova Week Complete'), findsOneWidget);
      expect(
        find.byKey(const Key('leaderboard_weekly_featured_accent')),
        findsOneWidget,
      );
    },
  );
}
