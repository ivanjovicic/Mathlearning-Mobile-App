import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/cosmetic_fragment_progress.dart';
import 'package:mathlearning/services/cosmetics_service.dart';

void main() {
  group('CosmeticsService Daily Run fragments', () {
    late CosmeticsService service;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      service = CosmeticsService.instance;
    });

    test(
      'persists fragment progress for the real Daily Run cosmetic item',
      () async {
        final first = await service.grantDailyRunFragment(
          fragmentName: 'Nova Trail Fragment',
        );

        expect(first.item.id, 'effect_nova_trail');
        expect(first.previousFragments, 0);
        expect(first.progress.collectedFragments, 1);
        expect(first.progress.requiredFragments, 5);
        expect(first.didUnlock, isFalse);

        final second = await service.grantDailyRunFragment(
          fragmentName: 'Nova Trail Fragment',
        );
        expect(second.previousFragments, 1);
        expect(second.progress.collectedFragments, 2);

        final saved = await service.loadFragmentProgress();
        final nova = saved.singleWhere(
          (entry) => entry.itemId == 'effect_nova_trail',
        );
        expect(nova.collectedFragments, 2);
        expect(nova.requiredFragments, 5);
      },
    );

    test(
      'unlocks the item and persists ownership at required fragments',
      () async {
        DailyRunCosmeticGrantResult? result;
        for (var i = 0; i < CosmeticsService.dailyRunRequiredFragments; i++) {
          result = await service.grantDailyRunFragment(
            fragmentName: 'Neon Number Burst Fragment',
          );
        }

        expect(result?.item.id, 'effect_neon_number_burst');
        expect(result?.progress.collectedFragments, 5);
        expect(result?.progress.isUnlocked, isTrue);
        expect(result?.didUnlock, isTrue);
        expect(result?.unlockedCosmetic?.itemId, 'effect_neon_number_burst');
        expect(
          await service.ownsItemLocally('effect_neon_number_burst'),
          isTrue,
        );

        final duplicate = await service.grantDailyRunFragment(
          fragmentName: 'Neon Number Burst Fragment',
        );
        expect(duplicate.progress.collectedFragments, 5);
        expect(duplicate.didUnlock, isFalse);
      },
    );

    test('maps Comet Frame fragments to an equipable avatar frame', () async {
      final result = await service.grantDailyRunFragment(
        fragmentName: 'Comet Frame Fragment',
      );

      expect(result.item.id, 'frame_comet');
      expect(result.item.category.id, 'avatar_frame');
      expect(result.progress.collectedFragments, 1);
    });
  });
}
