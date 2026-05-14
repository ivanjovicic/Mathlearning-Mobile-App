import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cosmetic_item.dart';
import '../models/player_identity.dart';
import '../models/user_cosmetic.dart';

/// Provides title computation (pure, no fake achievements) and preference
/// persistence for the player identity system.
///
/// Title logic operates only on real inventory data passed by the caller.
class PlayerIdentityService {
  static final PlayerIdentityService instance = PlayerIdentityService._();
  PlayerIdentityService._();

  /// Test-only subclassing constructor.
  @visibleForTesting
  PlayerIdentityService.test();

  static const String _prefixPrefs = 'player_identity.v1.';

  // ── Title computation ──────────────────────────────────────────────────────

  /// Returns the list of [PlayerTitle]s earned based on the supplied real data.
  /// No achievements are fabricated; returns an empty list when data is absent.
  List<PlayerTitle> computeEarnedTitles({
    required List<UserCosmetic> inventory,
    required List<CosmeticItem> catalog,
    required int currentStreak,
    required int totalAttempts,
    required int seasonCompletionPercent,
  }) {
    final ownedIds = inventory.map((c) => c.itemId).toSet();
    final ownedItems = catalog.where((c) => ownedIds.contains(c.id)).toList();

    final earned = <PlayerTitle>[];

    // Daily Run Master: 50+ total attempts
    if (totalAttempts >= 50) earned.add(PlayerTitle.dailyRunMaster);

    // Streak Keeper: 7+ day active streak
    if (currentStreak >= 7) earned.add(PlayerTitle.streakKeeper);

    // Nova Champion: owns the Nova Trail effect
    if (ownedIds.contains('effect_nova_trail')) {
      earned.add(PlayerTitle.novaChampion);
    }

    // Legendary: owns at least one legendary or mythic cosmetic
    final ownsLegendary = ownedItems.any(
      (i) =>
          i.rarity == CosmeticRarity.legendary ||
          i.rarity == CosmeticRarity.mythic,
    );
    if (ownsLegendary) earned.add(PlayerTitle.legendaryUnlock);

    // Season Veteran: completed a full season (100%)
    if (seasonCompletionPercent >= 100) earned.add(PlayerTitle.seasonVeteran);

    // Rare Hunter: 3+ rare-or-higher cosmetics
    final rareCount = ownedItems
        .where((i) => i.rarity.index >= CosmeticRarity.rare.index)
        .length;
    if (rareCount >= 3) earned.add(PlayerTitle.rareHunter);

    return earned;
  }

  /// Returns the rarest owned cosmetic item, or null if inventory is empty.
  ({
    CosmeticRarity rarity,
    String itemId,
    String name,
  })? rarestOwned({
    required List<UserCosmetic> inventory,
    required List<CosmeticItem> catalog,
  }) {
    if (inventory.isEmpty) return null;
    final ownedIds = inventory.map((c) => c.itemId).toSet();
    final ownedItems = catalog.where((c) => ownedIds.contains(c.id)).toList();
    if (ownedItems.isEmpty) return null;
    ownedItems.sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
    final top = ownedItems.first;
    return (rarity: top.rarity, itemId: top.id, name: top.name);
  }

  /// Builds trophy room entries from real inventory and progression data.
  /// Only includes items the user genuinely owns. Cap at 10 rare entries
  /// for list performance.
  List<TrophyEntry> buildTrophies({
    required List<UserCosmetic> inventory,
    required List<CosmeticItem> catalog,
    required int totalAttempts,
    String? completedSeasonName,
    String? completedSeasonId,
  }) {
    final ownedIds = inventory.map((c) => c.itemId).toSet();
    final ownedItems = catalog.where((c) => ownedIds.contains(c.id)).toList();

    final entries = <TrophyEntry>[];

    // Completed season
    if (completedSeasonId != null && completedSeasonName != null) {
      entries.add(
        TrophyEntry(
          id: 'season_$completedSeasonId',
          label: completedSeasonName,
          category: TrophyCategory.season,
          sublabel: 'Season completed',
          rarity: CosmeticRarity.epic,
        ),
      );
    }

    // Legendary / Mythic unlocks
    for (final item in ownedItems.where(
      (i) =>
          i.rarity == CosmeticRarity.legendary ||
          i.rarity == CosmeticRarity.mythic,
    )) {
      final uc = inventory
          .where((c) => c.itemId == item.id)
          .cast<UserCosmetic?>()
          .firstOrNull;
      entries.add(
        TrophyEntry(
          id: 'legendary_${item.id}',
          label: item.name,
          category: TrophyCategory.legendary,
          sublabel: item.rarity.label,
          rarity: item.rarity,
          earnedAt: uc?.unlockedAt,
        ),
      );
    }

    // Rare / Epic cosmetics (non-legendary), capped at 10
    final rareItems = ownedItems
        .where(
          (i) =>
              i.rarity == CosmeticRarity.epic ||
              i.rarity == CosmeticRarity.rare,
        )
        .take(10);
    for (final item in rareItems) {
      final uc = inventory
          .where((c) => c.itemId == item.id)
          .cast<UserCosmetic?>()
          .firstOrNull;
      entries.add(
        TrophyEntry(
          id: 'rare_${item.id}',
          label: item.name,
          category: TrophyCategory.rare,
          sublabel: item.rarity.label,
          rarity: item.rarity,
          earnedAt: uc?.unlockedAt,
        ),
      );
    }

    // Milestones based on attempts
    if (totalAttempts >= 50) {
      entries.add(
        const TrophyEntry(
          id: 'milestone_50_attempts',
          label: 'Daily Run Master',
          category: TrophyCategory.milestone,
          sublabel: '50 daily runs completed',
        ),
      );
    } else if (totalAttempts >= 10) {
      entries.add(
        const TrophyEntry(
          id: 'milestone_10_attempts',
          label: 'Getting Started',
          category: TrophyCategory.milestone,
          sublabel: '10 daily runs completed',
        ),
      );
    }

    return entries;
  }

  // ── Preferences persistence ────────────────────────────────────────────────

  Future<String?> loadSelectedTitle(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefixPrefs}title.$userId');
  }

  Future<void> saveSelectedTitle(String userId, String? titleId) async {
    final prefs = await SharedPreferences.getInstance();
    if (titleId == null) {
      await prefs.remove('${_prefixPrefs}title.$userId');
    } else {
      await prefs.setString('${_prefixPrefs}title.$userId', titleId);
    }
  }

  Future<String?> loadFavoriteCosmetic(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefixPrefs}favorite.$userId');
  }

  Future<void> saveFavoriteCosmetic(String userId, String? itemId) async {
    final prefs = await SharedPreferences.getInstance();
    if (itemId == null) {
      await prefs.remove('${_prefixPrefs}favorite.$userId');
    } else {
      await prefs.setString('${_prefixPrefs}favorite.$userId', itemId);
    }
  }
}
