import 'cosmetic_item.dart';

// ---------------------------------------------------------------------------
// Season status – derived from real start/end dates, never hardcoded.
// ---------------------------------------------------------------------------
enum SeasonStatus {
  active,
  endingSoon7d,
  endingSoon3d,
  endingSoon24h,
  ended;

  /// Human-readable urgency copy (kid-friendly, game-like).
  String get urgencyLabel {
    switch (this) {
      case SeasonStatus.active:
        return '';
      case SeasonStatus.endingSoon7d:
        return 'Season ending soon!';
      case SeasonStatus.endingSoon3d:
        return "Don't miss your rewards!";
      case SeasonStatus.endingSoon24h:
        return 'Final day! Grab your loot!';
      case SeasonStatus.ended:
        return 'Season over';
    }
  }

  bool get isUrgent =>
      this == endingSoon3d || this == endingSoon24h || this == ended;
}

// ---------------------------------------------------------------------------
// Reward types a milestone can grant.
// ---------------------------------------------------------------------------
enum SeasonRewardType {
  cosmeticFragment,
  cosmetic,
  badge,
  trail,
  profileEffect;

  String get label {
    switch (this) {
      case SeasonRewardType.cosmeticFragment:
        return 'Fragment';
      case SeasonRewardType.cosmetic:
        return 'Cosmetic';
      case SeasonRewardType.badge:
        return 'Badge';
      case SeasonRewardType.trail:
        return 'Trail';
      case SeasonRewardType.profileEffect:
        return 'Effect';
    }
  }

  static SeasonRewardType fromString(String value) {
    switch (value) {
      case 'cosmetic_fragment':
        return SeasonRewardType.cosmeticFragment;
      case 'cosmetic':
        return SeasonRewardType.cosmetic;
      case 'badge':
        return SeasonRewardType.badge;
      case 'trail':
        return SeasonRewardType.trail;
      case 'profile_effect':
        return SeasonRewardType.profileEffect;
      default:
        return SeasonRewardType.cosmetic;
    }
  }

  String get id {
    switch (this) {
      case SeasonRewardType.cosmeticFragment:
        return 'cosmetic_fragment';
      case SeasonRewardType.cosmetic:
        return 'cosmetic';
      case SeasonRewardType.badge:
        return 'badge';
      case SeasonRewardType.trail:
        return 'trail';
      case SeasonRewardType.profileEffect:
        return 'profile_effect';
    }
  }
}

// ---------------------------------------------------------------------------
// A single milestone in a season.
// ---------------------------------------------------------------------------
class SeasonMilestone {
  const SeasonMilestone({
    required this.id,
    required this.label,
    required this.xpRequired,
    required this.rewardType,
    required this.rewardId,
    this.rewardLabel,
    this.rarity = CosmeticRarity.common,
  });

  final String id;
  final String label;
  final int xpRequired;
  final SeasonRewardType rewardType;
  final String rewardId;
  final String? rewardLabel;
  final CosmeticRarity rarity;

  factory SeasonMilestone.fromJson(Map<String, dynamic> json) {
    return SeasonMilestone(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      xpRequired: _asInt(json['xp_required']) ?? 0,
      rewardType: SeasonRewardType.fromString(
        json['reward_type']?.toString() ?? 'cosmetic',
      ),
      rewardId: json['reward_id']?.toString() ?? '',
      rewardLabel: json['reward_label']?.toString(),
      rarity: CosmeticRarity.fromString(
        json['rarity']?.toString() ?? 'common',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'xp_required': xpRequired,
        'reward_type': rewardType.id,
        'reward_id': rewardId,
        'reward_label': rewardLabel,
        'rarity': rarity.name,
      };

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

// ---------------------------------------------------------------------------
// An active season.
// ---------------------------------------------------------------------------
class Season {
  const Season({
    required this.seasonId,
    required this.name,
    required this.theme,
    required this.startAt,
    required this.endAt,
    required this.featuredLegendaryCosmeticId,
    required this.milestones,
    required this.totalXpGoal,
  });

  final String seasonId;
  final String name;
  final String theme;
  final DateTime startAt;
  final DateTime endAt;
  final String featuredLegendaryCosmeticId;
  final List<SeasonMilestone> milestones;
  final int totalXpGoal;

  // ---------------------------------------------------------------------------
  // Derived – all logic based on real DateTime, never hardcoded offsets.
  // ---------------------------------------------------------------------------

  SeasonStatus status(DateTime now) {
    if (now.isAfter(endAt)) return SeasonStatus.ended;
    final remaining = endAt.difference(now);
    if (remaining.inHours <= 24) return SeasonStatus.endingSoon24h;
    if (remaining.inDays <= 3) return SeasonStatus.endingSoon3d;
    if (remaining.inDays <= 7) return SeasonStatus.endingSoon7d;
    return SeasonStatus.active;
  }

  Duration remaining(DateTime now) {
    if (now.isAfter(endAt)) return Duration.zero;
    return endAt.difference(now);
  }

  int daysRemaining(DateTime now) {
    final r = remaining(now);
    if (r == Duration.zero) return 0;
    return (r.inHours / 24).ceil().clamp(0, 999).toInt();
  }

  int hoursRemaining(DateTime now) {
    final r = remaining(now);
    return r.inHours.clamp(0, 9999).toInt();
  }

  String countdownLabel(DateTime now) {
    final hours = hoursRemaining(now);
    if (hours <= 0) return 'Ended';
    if (hours < 24) return '${hours}h left!';
    final days = daysRemaining(now);
    if (days == 1) return '1 day left!';
    return '$days days left';
  }

  double progressFraction(int xpEarned) {
    if (totalXpGoal <= 0) return 0;
    return (xpEarned / totalXpGoal).clamp(0.0, 1.0);
  }

  int completionPercent(int xpEarned) =>
      (progressFraction(xpEarned) * 100).round();

  List<SeasonMilestone> reachedMilestones(int xpEarned) =>
      milestones.where((m) => xpEarned >= m.xpRequired).toList();

  SeasonMilestone? nextMilestone(int xpEarned) {
    for (final m in milestones) {
      if (xpEarned < m.xpRequired) return m;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Serialisation (backend-compatible snake_case keys).
  // ---------------------------------------------------------------------------

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonId: json['season_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      theme: json['theme']?.toString() ?? 'default',
      startAt: DateTime.tryParse(json['start_at']?.toString() ?? '') ??
          DateTime.now(),
      endAt: DateTime.tryParse(json['end_at']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 90)),
      featuredLegendaryCosmeticId:
          json['featured_legendary_cosmetic_id']?.toString() ?? '',
      milestones: (json['milestones'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SeasonMilestone.fromJson)
          .toList(),
      totalXpGoal: _asInt(json['total_xp_goal']) ?? 500,
    );
  }

  Map<String, dynamic> toJson() => {
        'season_id': seasonId,
        'name': name,
        'theme': theme,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'featured_legendary_cosmetic_id': featuredLegendaryCosmeticId,
        'milestones': milestones.map((m) => m.toJson()).toList(),
        'total_xp_goal': totalXpGoal,
      };

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Per-user progress for a season – persisted locally.
// ---------------------------------------------------------------------------
class SeasonProgress {
  const SeasonProgress({
    required this.seasonId,
    required this.userId,
    required this.earnedXp,
    required this.claimedMilestoneIds,
    required this.archivedBadgeIds,
  });

  final String seasonId;
  final String userId;
  final int earnedXp;
  final Set<String> claimedMilestoneIds;
  /// Badge IDs archived when a season ends. Preserves history across resets.
  final Set<String> archivedBadgeIds;

  SeasonProgress copyWith({
    int? earnedXp,
    Set<String>? claimedMilestoneIds,
    Set<String>? archivedBadgeIds,
  }) {
    return SeasonProgress(
      seasonId: seasonId,
      userId: userId,
      earnedXp: earnedXp ?? this.earnedXp,
      claimedMilestoneIds: claimedMilestoneIds ?? this.claimedMilestoneIds,
      archivedBadgeIds: archivedBadgeIds ?? this.archivedBadgeIds,
    );
  }

  factory SeasonProgress.empty({
    required String seasonId,
    required String userId,
  }) {
    return SeasonProgress(
      seasonId: seasonId,
      userId: userId,
      earnedXp: 0,
      claimedMilestoneIds: const {},
      archivedBadgeIds: const {},
    );
  }

  factory SeasonProgress.fromJson(Map<String, dynamic> json) {
    return SeasonProgress(
      seasonId: json['season_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      earnedXp: _asInt(json['earned_xp']) ?? 0,
      claimedMilestoneIds: (json['claimed_milestone_ids'] as List<dynamic>? ??
              [])
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toSet(),
      archivedBadgeIds:
          (json['archived_badge_ids'] as List<dynamic>? ?? [])
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toSet(),
    );
  }

  Map<String, dynamic> toJson() => {
        'season_id': seasonId,
        'user_id': userId,
        'earned_xp': earnedXp,
        'claimed_milestone_ids': claimedMilestoneIds.toList(),
        'archived_badge_ids': archivedBadgeIds.toList(),
      };

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

// ---------------------------------------------------------------------------
// Result returned when a milestone reward is claimed.
// ---------------------------------------------------------------------------
class SeasonMilestoneClaimResult {
  const SeasonMilestoneClaimResult({
    required this.milestone,
    required this.success,
    this.errorReason,
  });

  final SeasonMilestone milestone;
  final bool success;
  final String? errorReason;
}
