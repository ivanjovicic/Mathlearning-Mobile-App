import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/player_identity.dart';
import 'package:mathlearning/models/user_cosmetic.dart';
import 'package:mathlearning/services/player_identity_service.dart';
import 'package:mathlearning/state/player_identity_provider.dart';

// ── Stub service ──────────────────────────────────────────────────────────────

class _StubService extends PlayerIdentityService {
  _StubService() : super.test();

  String? savedTitle;
  String? savedFavorite;
  bool loadCalled = false;

  @override
  Future<String?> loadSelectedTitle(String userId) async {
    loadCalled = true;
    return savedTitle;
  }

  @override
  Future<void> saveSelectedTitle(String userId, String? titleId) async {
    savedTitle = titleId;
  }

  @override
  Future<String?> loadFavoriteCosmetic(String userId) async => savedFavorite;

  @override
  Future<void> saveFavoriteCosmetic(String userId, String? itemId) async {
    savedFavorite = itemId;
  }
}

// ── Test helpers ──────────────────────────────────────────────────────────────

CosmeticItem _item(String id, CosmeticRarity rarity) => CosmeticItem(
      id: id,
      name: 'Item $id',
      category: CosmeticCategory.animatedEffect,
      rarity: rarity,
      unlockCondition: '',
      assetKey: '',
      createdAt: DateTime(2026),
    );

UserCosmetic _owned(String itemId) => UserCosmetic(
      id: 'uc_$itemId',
      userId: 'user-1',
      itemId: itemId,
      unlockedAt: DateTime(2026),
      sourceType: 'manual',
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('PlayerIdentityProvider — title computation', () {
    test('no titles earned when inventory is empty and no progress', () async {
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );

      expect(provider.earnedTitles, isEmpty);
    });

    test('dailyRunMaster earned at 50+ total attempts only', () async {
      final catalog = [_item('effect_a', CosmeticRarity.common)];
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      // 49 attempts — should NOT earn the title
      provider.refresh(
        inventory: [_owned('effect_a')],
        catalog: catalog,
        currentStreak: 0,
        totalAttempts: 49,
        seasonCompletionPercent: 0,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.dailyRunMaster), isFalse);

      // 50 attempts — should earn
      provider.refresh(
        inventory: [_owned('effect_a')],
        catalog: catalog,
        currentStreak: 0,
        totalAttempts: 50,
        seasonCompletionPercent: 0,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.dailyRunMaster), isTrue);
    });

    test('streakKeeper earned at 7+ streak only', () async {
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 6,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.streakKeeper), isFalse);

      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 7,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.streakKeeper), isTrue);
    });

    test('novaChampion earned only when nova trail is owned', () async {
      final novaItem = _item('effect_nova_trail', CosmeticRarity.rare);
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      // Without nova trail
      provider.refresh(
        inventory: const [],
        catalog: [novaItem],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.novaChampion), isFalse);

      // With nova trail
      provider.refresh(
        inventory: [_owned('effect_nova_trail')],
        catalog: [novaItem],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.novaChampion), isTrue);
    });

    test('legendaryUnlock earned when at least one legendary item owned', () async {
      final legendary = _item('bg_legendary', CosmeticRarity.legendary);
      final epic = _item('bg_epic', CosmeticRarity.epic);
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      // Only epic — should NOT earn legendaryUnlock
      provider.refresh(
        inventory: [_owned('bg_epic')],
        catalog: [legendary, epic],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(
        provider.earnedTitles.contains(PlayerTitle.legendaryUnlock),
        isFalse,
      );

      // With legendary
      provider.refresh(
        inventory: [_owned('bg_legendary')],
        catalog: [legendary, epic],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(
        provider.earnedTitles.contains(PlayerTitle.legendaryUnlock),
        isTrue,
      );
    });

    test('rareHunter requires 3 or more rare+ cosmetics', () async {
      final items = [
        _item('r1', CosmeticRarity.rare),
        _item('r2', CosmeticRarity.rare),
        _item('r3', CosmeticRarity.rare),
        _item('c1', CosmeticRarity.common),
      ];
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      // Only 2 rare items
      provider.refresh(
        inventory: [_owned('r1'), _owned('r2')],
        catalog: items,
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.rareHunter), isFalse);

      // 3 rare items
      provider.refresh(
        inventory: [_owned('r1'), _owned('r2'), _owned('r3')],
        catalog: items,
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.rareHunter), isTrue);
    });

    test('seasonVeteran requires 100% completion', () async {
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 99,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.seasonVeteran), isFalse);

      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 100,
      );
      expect(provider.earnedTitles.contains(PlayerTitle.seasonVeteran), isTrue);
    });
  });

  group('PlayerIdentityProvider — preferences', () {
    test('setSelectedTitle persists to service', () async {
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      // Earn the title first
      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 7,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );

      await provider.setSelectedTitle(PlayerTitle.streakKeeper);

      expect(provider.selectedTitleId, PlayerTitle.streakKeeper.name);
      expect(stub.savedTitle, PlayerTitle.streakKeeper.name);
    });

    test('setSelectedTitle rejected when title not earned', () async {
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      // No titles earned
      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );

      await provider.setSelectedTitle(PlayerTitle.legendaryUnlock);

      expect(provider.selectedTitleId, isNull);
      expect(stub.savedTitle, isNull);
    });

    test('selected title cleared when title no longer earned', () async {
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      // Earn streak keeper, select it
      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 7,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      await provider.setSelectedTitle(PlayerTitle.streakKeeper);
      expect(provider.selectedTitleId, PlayerTitle.streakKeeper.name);

      // Streak drops — title cleared
      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 0,
        totalAttempts: 0,
        seasonCompletionPercent: 0,
      );
      expect(provider.selectedTitleId, isNull);
    });

    test('setFavoriteCosmetic persists to service', () async {
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      await provider.setFavoriteCosmetic('effect_nova_trail');

      expect(provider.favoriteCosmeticId, 'effect_nova_trail');
      expect(stub.savedFavorite, 'effect_nova_trail');
    });

    test('preferences loaded from service on configureUser', () async {
      final stub = _StubService()
        ..savedTitle = PlayerTitle.streakKeeper.name
        ..savedFavorite = 'bg_galaxy';

      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      expect(stub.loadCalled, isTrue);
      // Title ID loaded — NOTE: earnedTitles is empty until refresh() is called,
      // so featuredTitle will not return it yet; but selectedTitleId is set.
      expect(provider.selectedTitleId, PlayerTitle.streakKeeper.name);
      expect(provider.favoriteCosmeticId, 'bg_galaxy');
    });

    test('configureUser resets state for new user', () async {
      final stub = _StubService();
      final provider = PlayerIdentityProvider(service: stub);
      await provider.configureUserAndWait('user-1');

      provider.refresh(
        inventory: const [],
        catalog: const [],
        currentStreak: 7,
        totalAttempts: 50,
        seasonCompletionPercent: 0,
      );

      expect(provider.earnedTitles, isNotEmpty);

      // Switch user
      await provider.configureUserAndWait('user-2');
      expect(provider.earnedTitles, isEmpty);
      expect(provider.selectedTitleId, isNull);
    });
  });

  group('PlayerIdentityProvider — trophy room', () {
    test('buildTrophies includes legendary unlocks', () {
      final service = PlayerIdentityService.test();
      final catalog = [
        _item('bg_legendary', CosmeticRarity.legendary),
        _item('bg_common', CosmeticRarity.common),
      ];
      final trophies = service.buildTrophies(
        inventory: [_owned('bg_legendary')],
        catalog: catalog,
        totalAttempts: 0,
      );

      expect(
        trophies.any(
          (t) => t.category == TrophyCategory.legendary && t.id.contains('bg_legendary'),
        ),
        isTrue,
      );
    });

    test('buildTrophies does not include unowned items', () {
      final service = PlayerIdentityService.test();
      final catalog = [
        _item('bg_legendary', CosmeticRarity.legendary),
      ];
      final trophies = service.buildTrophies(
        inventory: const [],
        catalog: catalog,
        totalAttempts: 0,
      );

      expect(
        trophies.any((t) => t.id.contains('bg_legendary')),
        isFalse,
      );
    });

    test('milestone trophy added at 50+ attempts', () {
      final service = PlayerIdentityService.test();
      final trophies = service.buildTrophies(
        inventory: const [],
        catalog: const [],
        totalAttempts: 50,
      );

      expect(
        trophies.any((t) => t.id == 'milestone_50_attempts'),
        isTrue,
      );
    });

    test('no milestone trophy below 10 attempts', () {
      final service = PlayerIdentityService.test();
      final trophies = service.buildTrophies(
        inventory: const [],
        catalog: const [],
        totalAttempts: 5,
      );

      expect(trophies.where((t) => t.category == TrophyCategory.milestone), isEmpty);
    });

    test('season trophy included when season is completed', () {
      final service = PlayerIdentityService.test();
      final trophies = service.buildTrophies(
        inventory: const [],
        catalog: const [],
        totalAttempts: 0,
        completedSeasonName: 'Winter 2026',
        completedSeasonId: 'season_w26',
      );

      expect(
        trophies.any((t) => t.category == TrophyCategory.season),
        isTrue,
      );
    });
  });

  group('PlayerIdentityService — rarestOwned', () {
    test('returns null when inventory empty', () {
      final service = PlayerIdentityService.test();
      final result = service.rarestOwned(
        inventory: const [],
        catalog: const [],
      );
      expect(result, isNull);
    });

    test('returns highest rarity item', () {
      final service = PlayerIdentityService.test();
      final catalog = [
        _item('item_common', CosmeticRarity.common),
        _item('item_epic', CosmeticRarity.epic),
        _item('item_rare', CosmeticRarity.rare),
      ];
      final result = service.rarestOwned(
        inventory: [
          _owned('item_common'),
          _owned('item_epic'),
          _owned('item_rare'),
        ],
        catalog: catalog,
      );

      expect(result?.rarity, CosmeticRarity.epic);
      expect(result?.itemId, 'item_epic');
    });
  });
}
