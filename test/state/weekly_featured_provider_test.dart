import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/user_cosmetic.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/weekly_featured_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('rotation persists for the same user and week', () async {
    final now = DateTime(2026, 5, 14);
    final first = WeeklyFeaturedProvider();
    await first.load(userId: 'user-1', now: now);

    final restored = WeeklyFeaturedProvider();
    await restored.load(userId: 'user-1', now: now);

    expect(restored.activeSet?.rotationId, first.activeSet?.rotationId);
    expect(restored.activeSet?.title, 'NOVA WEEK');
    expect(restored.activeSet?.itemIds.length, inInclusiveRange(3, 5));
  });

  test('weekly set completion is tracked from real owned inventory', () async {
    final now = DateTime(2026, 5, 14);
    final provider = WeeklyFeaturedProvider();
    await provider.load(userId: 'user-1', now: now);
    final set = provider.activeSet!;

    await provider.refreshCompletionFromInventory(
      set.itemIds
          .map(
            (itemId) => UserCosmetic(
              id: 'owned-$itemId',
              userId: 'user-1',
              itemId: itemId,
              unlockedAt: now,
              sourceType: 'test',
            ),
          )
          .toList(growable: false),
    );

    expect(provider.completedActiveSet, isTrue);

    final restored = WeeklyFeaturedProvider();
    await restored.load(userId: 'user-1', now: now);
    expect(restored.completedActiveSet, isTrue);
  });

  test(
    'featured boost can replace non-featured chest fragment deterministically',
    () async {
      final provider = WeeklyFeaturedProvider();
      await provider.load(userId: 'user-1', now: DateTime(2026, 5, 14));

      const base = DailyChestReward(
        xp: 30,
        coins: 12,
        cosmeticFragment: 'Unknown Fragment',
      );
      var boosted = base;
      for (var day = 14; day <= 21; day++) {
        boosted = provider.applyFeaturedBoost(
          base,
          now: DateTime(2026, 5, day),
        );
        if (boosted.cosmeticFragment != base.cosmeticFragment) break;
      }

      expect(boosted.xp, base.xp);
      expect(boosted.coins, base.coins);
      expect(boosted.cosmeticFragment, isNot(base.cosmeticFragment));
      expect(
        <String>{
          'Nova Trail Fragment',
          'Comet Frame Fragment',
          'Neon Number Burst Fragment',
        }.contains(boosted.cosmeticFragment),
        isTrue,
      );
    },
  );
}
