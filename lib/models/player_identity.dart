import 'cosmetic_item.dart';

/// A title a player can earn and display on their profile.
enum PlayerTitle {
  dailyRunMaster,
  streakKeeper,
  novaChampion,
  legendaryUnlock,
  seasonVeteran,
  rareHunter;

  String get label {
    switch (this) {
      case dailyRunMaster:
        return 'Daily Run Master';
      case streakKeeper:
        return 'Streak Keeper';
      case novaChampion:
        return 'Nova Champion';
      case legendaryUnlock:
        return 'Legendary';
      case seasonVeteran:
        return 'Season Veteran';
      case rareHunter:
        return 'Rare Hunter';
    }
  }

  String get unlockCriteria {
    switch (this) {
      case dailyRunMaster:
        return 'Complete 50 daily runs';
      case streakKeeper:
        return 'Maintain a 7-day streak';
      case novaChampion:
        return 'Unlock the Nova Trail effect';
      case legendaryUnlock:
        return 'Own a Legendary cosmetic';
      case seasonVeteran:
        return 'Complete a full season track';
      case rareHunter:
        return 'Collect 3 or more Rare+ cosmetics';
    }
  }
}

/// A single entry in the trophy room.
class TrophyEntry {
  const TrophyEntry({
    required this.id,
    required this.label,
    required this.category,
    this.sublabel,
    this.rarity,
    this.earnedAt,
  });

  final String id;
  final String label;
  final TrophyCategory category;
  final String? sublabel;
  final CosmeticRarity? rarity;
  final DateTime? earnedAt;
}

/// Grouping category for trophy room entries.
enum TrophyCategory {
  season,
  legendary,
  rare,
  milestone;

  String get sectionLabel {
    switch (this) {
      case season:
        return 'Completed Seasons';
      case legendary:
        return 'Legendary Unlocks';
      case rare:
        return 'Rare Cosmetics';
      case milestone:
        return 'Milestones';
    }
  }
}

/// Persisted user identity preferences (selected title + favorite cosmetic).
class PlayerIdentityPrefs {
  const PlayerIdentityPrefs({
    required this.selectedTitleId,
    required this.favoriteCosmeticId,
  });

  final String? selectedTitleId;
  final String? favoriteCosmeticId;

  static const PlayerIdentityPrefs empty = PlayerIdentityPrefs(
    selectedTitleId: null,
    favoriteCosmeticId: null,
  );

  PlayerIdentityPrefs copyWith({
    String? selectedTitleId,
    String? favoriteCosmeticId,
  }) {
    return PlayerIdentityPrefs(
      selectedTitleId: selectedTitleId ?? this.selectedTitleId,
      favoriteCosmeticId: favoriteCosmeticId ?? this.favoriteCosmeticId,
    );
  }
}
