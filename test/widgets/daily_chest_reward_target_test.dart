import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/features/learning_map/widgets/cosmetic_unlock_celebration.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_chest_reward_sheet.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/state/daily_run_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpMs(WidgetTester tester, int totalMs) async {
    const stepMs = 50;
    var elapsed = 0;
    while (elapsed < totalMs) {
      final step = (totalMs - elapsed).clamp(0, stepMs);
      await tester.pump(Duration(milliseconds: step));
      elapsed += step;
    }
  }

  Widget buildSheet({
    required int fragmentCount,
    required CosmeticTargetProgressEvent event,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DailyChestRewardSheet(
            reward: const DailyChestReward(
              xp: 30,
              coins: 12,
              cosmeticFragment: 'Comet Frame Fragment',
            ),
            startOpen: true,
            fragmentCountForTesting: fragmentCount,
            onApplyTargetProgress: (_) async => event,
            onContinue: () {},
            onEquipNow: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('target fragment drop gets special reveal treatment', (
    tester,
  ) async {
    const target = CosmeticTarget(
      targetCosmeticItemId: 'frame_comet',
      targetFragmentsOwned: 4,
      targetFragmentsRequired: 5,
      targetRarity: CosmeticRarity.rare,
      targetItemName: 'Comet Frame',
      targetSlotLabel: 'Frame',
    );

    await tester.pumpWidget(
      buildSheet(
        fragmentCount: 4,
        event: const CosmeticTargetProgressEvent(
          target: target,
          previousFragments: 3,
          currentFragments: 4,
          targetFragmentFound: true,
        ),
      ),
    );
    await tester.pump();
    await pumpMs(tester, 4500);

    expect(
      find.byKey(const Key('target_fragment_found_banner')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('target_fragment_confetti_burst')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('reward_fullscreen_flash')),
      findsAtLeastNWidgets(1),
    );
    expect(find.byKey(const Key('rarity_particle_explosion')), findsOneWidget);
    expect(find.byKey(const Key('reward_chest_shake')), findsOneWidget);
    expect(find.text('TARGET FRAGMENT FOUND!'), findsAtLeastNWidgets(1));
    expect(
      find.text('You are now 1 fragment closer to Comet Frame.'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('target completion still opens unlock ceremony with equip CTA', (
    tester,
  ) async {
    const target = CosmeticTarget(
      targetCosmeticItemId: 'frame_comet',
      targetFragmentsOwned: 5,
      targetFragmentsRequired: 5,
      targetRarity: CosmeticRarity.rare,
      targetItemName: 'Comet Frame',
      targetSlotLabel: 'Frame',
    );

    await tester.pumpWidget(
      buildSheet(
        fragmentCount: 5,
        event: const CosmeticTargetProgressEvent(
          target: target,
          previousFragments: 4,
          currentFragments: 5,
          targetFragmentFound: true,
        ),
      ),
    );
    await tester.pump();
    await pumpMs(tester, 10000);
    await tester.pump();

    expect(find.byType(CosmeticUnlockCelebration), findsOneWidget);
    expect(find.textContaining('UNLOCKED!'), findsOneWidget);
    expect(find.text('Equip now'), findsAtLeastNWidgets(1));
  });
}
