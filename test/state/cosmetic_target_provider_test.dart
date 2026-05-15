import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/cosmetic_fragment_progress.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/services/cosmetics_service.dart';
import 'package:mathlearning/state/cosmetic_target_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('set target flow persists local target state', () async {
    final provider = CosmeticTargetProvider();
    await provider.load(userId: 'user-1');

    await provider.setTargetFromFlexItem(
      item: const SocialCosmeticFlexItem(
        itemId: 'frame_comet',
        name: 'Comet Frame',
        rarity: CosmeticRarity.rare,
        slotLabel: 'Frame',
        hasActualName: true,
      ),
      progress: CosmeticFragmentProgress(
        itemId: 'frame_comet',
        collectedFragments: 3,
        requiredFragments: 5,
        updatedAt: DateTime(2026),
      ),
    );

    final restored = CosmeticTargetProvider();
    await restored.load(userId: 'user-1');

    expect(restored.target?.targetCosmeticItemId, 'frame_comet');
    expect(restored.target?.targetFragmentsOwned, 3);
    expect(restored.target?.targetFragmentsRequired, 5);
    expect(restored.target?.targetRarity, CosmeticRarity.rare);
    expect(restored.target?.displayName, 'Comet Frame');
  });

  test('target fragment grant updates target progress', () async {
    final item = CosmeticsService.instance.getCatalog().firstWhere(
      (entry) => entry.id == 'frame_comet',
    );
    final provider = CosmeticTargetProvider();
    await provider.load(userId: 'user-1');
    await provider.setTargetFromCatalogItem(
      item: item,
      progress: CosmeticFragmentProgress(
        itemId: item.id,
        collectedFragments: 3,
        requiredFragments: 5,
        updatedAt: DateTime(2026),
      ),
    );

    final event = await provider.applyDailyRunGrant(
      DailyRunCosmeticGrantResult(
        item: item,
        progress: CosmeticFragmentProgress(
          itemId: item.id,
          collectedFragments: 4,
          requiredFragments: 5,
          updatedAt: DateTime(2026, 1, 2),
        ),
        previousFragments: 3,
        didUnlock: false,
      ),
    );

    expect(event?.targetFragmentFound, isTrue);
    expect(event?.fragmentsGained, 1);
    expect(provider.target?.targetFragmentsOwned, 4);
  });

  test(
    'non-target grant awards target energy without fake fragments',
    () async {
      final catalog = CosmeticsService.instance.getCatalog();
      final frame = catalog.firstWhere((entry) => entry.id == 'frame_comet');
      final nova = catalog.firstWhere(
        (entry) => entry.id == 'effect_nova_trail',
      );
      final provider = CosmeticTargetProvider();
      await provider.load(userId: 'user-1');
      await provider.setTargetFromCatalogItem(
        item: frame,
        progress: CosmeticFragmentProgress(
          itemId: frame.id,
          collectedFragments: 2,
          requiredFragments: 5,
          updatedAt: DateTime(2026),
        ),
      );

      final event = await provider.applyDailyRunGrant(
        DailyRunCosmeticGrantResult(
          item: nova,
          progress: CosmeticFragmentProgress(
            itemId: nova.id,
            collectedFragments: 1,
            requiredFragments: 5,
            updatedAt: DateTime(2026, 1, 2),
          ),
          previousFragments: 0,
          didUnlock: false,
        ),
      );

      expect(event?.targetFragmentFound, isFalse);
      expect(event?.bonusProgressAwarded, 1);
      expect(provider.target?.targetFragmentsOwned, 2);
      expect(provider.target?.bonusProgress, 1);
    },
  );

  test('bonus fragment awarded when bonus progress crosses threshold', () async {
    final catalog = CosmeticsService.instance.getCatalog();
    final frame = catalog.firstWhere((entry) => entry.id == 'frame_comet');
    final nova = catalog.firstWhere(
      (entry) => entry.id == 'effect_nova_trail',
    );

    final provider = CosmeticTargetProvider();
    await provider.load(userId: 'user-bonus');

    // Start with 4 progress segments already accumulated (4 prior non-target runs).
    await provider.setTargetFromCatalogItem(
      item: frame,
      progress: CosmeticFragmentProgress(
        itemId: frame.id,
        collectedFragments: 1,
        requiredFragments: 5,
        updatedAt: DateTime(2026),
      ),
    );
    // Manually seed progress by running 4 non-target grants.
    for (var i = 0; i < 4; i++) {
      await provider.applyDailyRunGrant(
        DailyRunCosmeticGrantResult(
          item: nova,
          progress: CosmeticFragmentProgress(
            itemId: nova.id,
            collectedFragments: i + 1,
            requiredFragments: 5,
            updatedAt: DateTime(2026),
          ),
          previousFragments: i,
          didUnlock: false,
        ),
      );
    }

    expect(
      provider.target?.bonusProgress,
      4,
      reason: '4 x 1 segment = 4, below threshold of 5',
    );
    expect(provider.target?.targetFragmentsOwned, 1);

    // 5th non-target run: 4 + 1 = 5 → threshold reached.
    final bonusEvent = await provider.applyDailyRunGrant(
      DailyRunCosmeticGrantResult(
        item: nova,
        progress: CosmeticFragmentProgress(
          itemId: nova.id,
          collectedFragments: 5,
          requiredFragments: 5,
          updatedAt: DateTime(2026),
        ),
        previousFragments: 4,
        didUnlock: false,
      ),
    );

    expect(bonusEvent?.bonusFragmentEarned, isTrue);
    expect(bonusEvent?.targetFragmentFound, isTrue);
    expect(bonusEvent?.bonusProgressAwarded, 1);
    // +1 bonus fragment awarded.
    expect(provider.target?.targetFragmentsOwned, 2);
    // Progress resets: 5 - 5 = 0.
    expect(provider.target?.bonusProgress, 0);
  });

  test('bonus progress max constant is 5 (one per run, five to bonus)', () async {
    expect(CosmeticTarget.kBonusProgressMax, 5);
  });

  test(
    'energy does not cross threshold on sub-threshold non-target run',
    () async {
      final catalog = CosmeticsService.instance.getCatalog();
      final frame = catalog.firstWhere((entry) => entry.id == 'frame_comet');
      final nova = catalog.firstWhere(
        (entry) => entry.id == 'effect_nova_trail',
      );

      final provider = CosmeticTargetProvider();
      await provider.load(userId: 'user-sub');
      await provider.setTargetFromCatalogItem(
        item: frame,
        progress: CosmeticFragmentProgress(
          itemId: frame.id,
          collectedFragments: 2,
          requiredFragments: 5,
          updatedAt: DateTime(2026),
        ),
      );

      // 3 runs: 3 progress segments, still below threshold of 5.
      for (var i = 0; i < 3; i++) {
        final event = await provider.applyDailyRunGrant(
          DailyRunCosmeticGrantResult(
            item: nova,
            progress: CosmeticFragmentProgress(
              itemId: nova.id,
              collectedFragments: i + 1,
              requiredFragments: 5,
              updatedAt: DateTime(2026),
            ),
            previousFragments: i,
            didUnlock: false,
          ),
        );
        expect(event?.bonusFragmentEarned, isFalse);
        expect(event?.targetFragmentFound, isFalse);
      }
      expect(provider.target?.bonusProgress, 3);
      expect(provider.target?.targetFragmentsOwned, 2);
    },
  );
}
