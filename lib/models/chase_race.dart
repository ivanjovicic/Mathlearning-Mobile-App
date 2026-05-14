import 'package:flutter/foundation.dart';

import 'cosmetic_item.dart';
import 'social_cosmetic_loadout.dart';

/// One participant in a cosmetic chase race.
class ChaseRaceEntry {
  const ChaseRaceEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.cosmeticLoadout,
    required this.itemId,
    required this.fragmentsOwned,
    required this.fragmentsRequired,
    this.todayGained = 0,
    this.completedAt,
    this.rank = 0,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final SocialCosmeticLoadout? cosmeticLoadout;
  final String itemId;
  final int fragmentsOwned;
  final int fragmentsRequired;

  /// Fragments earned today (as reported by the backend).
  final int todayGained;

  /// When the chase was completed; null if not yet finished.
  final DateTime? completedAt;

  /// 1-based race rank assigned by [ChaseRace._sortAndRank].
  final int rank;

  bool get isComplete =>
      fragmentsRequired > 0 && fragmentsOwned >= fragmentsRequired;

  double get progressValue {
    if (fragmentsRequired <= 0) return 0.0;
    return (fragmentsOwned / fragmentsRequired).clamp(0.0, 1.0);
  }

  int get remainingFragments =>
      (fragmentsRequired - fragmentsOwned).clamp(0, 999).toInt();

  ChaseRaceEntry copyWith({
    String? displayName,
    SocialCosmeticLoadout? cosmeticLoadout,
    int? fragmentsOwned,
    int? todayGained,
    DateTime? completedAt,
    int? rank,
  }) {
    return ChaseRaceEntry(
      userId: userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl,
      cosmeticLoadout: cosmeticLoadout ?? this.cosmeticLoadout,
      itemId: itemId,
      fragmentsOwned: fragmentsOwned ?? this.fragmentsOwned,
      fragmentsRequired: fragmentsRequired,
      todayGained: todayGained ?? this.todayGained,
      completedAt: completedAt ?? this.completedAt,
      rank: rank ?? this.rank,
    );
  }

  factory ChaseRaceEntry.fromJson(Map<String, dynamic> json) {
    return ChaseRaceEntry(
      userId: _asString(json['user_id'] ?? json['userId']),
      displayName: _asString(json['display_name'] ?? json['displayName']),
      avatarUrl: _asNullableString(json['avatar_url'] ?? json['avatarUrl']),
      cosmeticLoadout: socialCosmeticLoadoutFromJson(json),
      itemId: _asString(json['item_id'] ?? json['itemId']),
      fragmentsOwned:
          (_asInt(json['fragments_owned'] ?? json['fragmentsOwned']) ?? 0)
              .clamp(0, 999)
              .toInt(),
      fragmentsRequired:
          (_asInt(json['fragments_required'] ?? json['fragmentsRequired']) ?? 5)
              .clamp(1, 999)
              .toInt(),
      todayGained:
          (_asInt(json['today_gained'] ?? json['todayGained']) ?? 0)
              .clamp(0, 999)
              .toInt(),
      completedAt: DateTime.tryParse(
        _asString(json['completed_at'] ?? json['completedAt']),
      ),
      rank: _asInt(json['rank']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'display_name': displayName,
    'avatar_url': avatarUrl,
    'item_id': itemId,
    'fragments_owned': fragmentsOwned,
    'fragments_required': fragmentsRequired,
    'today_gained': todayGained,
    'completed_at': completedAt?.toIso8601String(),
    'rank': rank,
  };
}

/// Snapshot of a chase race for a specific cosmetic item.
///
/// Participants are always sorted and ranked by [_sortAndRank]:
/// 1. Completed entries first, ordered by [ChaseRaceEntry.completedAt] ascending.
/// 2. Incomplete entries sorted by [ChaseRaceEntry.fragmentsOwned] descending.
/// 3. Tie-broken by userId for stable ordering.
class ChaseRace {
  const ChaseRace({
    required this.itemId,
    required this.itemName,
    required this.itemRarity,
    required this.participants,
  });

  final String itemId;
  final String itemName;
  final CosmeticRarity itemRarity;

  /// Sorted, ranked participant list (rank 1 = furthest along / first to
  /// finish). Populated via [fromJson] or [withUpdatedEntry]; the default
  /// constructor leaves participants unranked (useful for tests).
  final List<ChaseRaceEntry> participants;

  bool get isEmpty => participants.isEmpty;

  /// True only when there is at least one *other* participant — a solo chase
  /// is never displayed as a race.
  bool get hasCompetitors => participants.length > 1;

  /// The first participant to finish (earliest [ChaseRaceEntry.completedAt]).
  ChaseRaceEntry? get firstFinisher =>
      participants.where((e) => e.isComplete).firstOrNull;

  /// Returns the entry for [userId], or null.
  ChaseRaceEntry? entryFor(String userId) =>
      participants.where((e) => e.userId == userId).firstOrNull;

  factory ChaseRace.fromJson(
    Map<String, dynamic> json, {
    required CosmeticRarity itemRarity,
  }) {
    final rawList = json['participants'];
    final unranked = rawList is List
        ? rawList
            .whereType<Map>()
            .map((e) => ChaseRaceEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <ChaseRaceEntry>[];

    return ChaseRace(
      itemId: _asString(json['item_id'] ?? json['itemId']),
      itemName: _asString(json['item_name'] ?? json['itemName']),
      itemRarity: itemRarity,
      participants: _sortAndRank(unranked),
    );
  }

  /// Replaces (or inserts) an entry for the given user and re-ranks.
  ChaseRace withUpdatedEntry(ChaseRaceEntry updated) {
    final list = <ChaseRaceEntry>[
      for (final e in participants)
        if (e.userId != updated.userId) e,
      updated,
    ];
    return ChaseRace(
      itemId: itemId,
      itemName: itemName,
      itemRarity: itemRarity,
      participants: _sortAndRank(list),
    );
  }

  static List<ChaseRaceEntry> _sortAndRank(List<ChaseRaceEntry> entries) {
    final sorted = List<ChaseRaceEntry>.from(entries);
    sorted.sort((a, b) {
      // Completed entries are always ranked above incomplete ones.
      if (a.isComplete && !b.isComplete) return -1;
      if (!a.isComplete && b.isComplete) return 1;
      if (a.isComplete && b.isComplete) {
        final ca = a.completedAt ?? DateTime.utc(9999);
        final cb = b.completedAt ?? DateTime.utc(9999);
        return ca.compareTo(cb);
      }
      // Incomplete: most fragments first; userId for stability.
      final diff = b.fragmentsOwned.compareTo(a.fragmentsOwned);
      return diff != 0 ? diff : a.userId.compareTo(b.userId);
    });
    return sorted
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(rank: entry.key + 1))
        .toList();
  }

  /// Exposed so tests can verify ranking logic directly.
  @visibleForTesting
  static List<ChaseRaceEntry> sortAndRankForTest(
    List<ChaseRaceEntry> entries,
  ) => _sortAndRank(entries);
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _asString(dynamic value, {String fallback = ''}) {
  final safe = value?.toString().trim();
  if (safe == null || safe.isEmpty) return fallback;
  return safe;
}

String? _asNullableString(dynamic value) {
  final safe = value?.toString().trim();
  if (safe == null || safe.isEmpty) return null;
  return safe;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
