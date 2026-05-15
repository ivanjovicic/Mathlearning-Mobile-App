import 'cosmetic_item.dart';

class WeeklyFeaturedCosmeticSet {
  const WeeklyFeaturedCosmeticSet({
    required this.rotationId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.headlineItemId,
    required this.itemIds,
    required this.badgeName,
    required this.profileFlair,
    required this.leaderboardAccentLabel,
  });

  final String rotationId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String headlineItemId;
  final List<String> itemIds;
  final String badgeName;
  final String profileFlair;
  final String leaderboardAccentLabel;

  bool containsItem(String itemId) => itemIds.contains(itemId);

  bool isActive(DateTime now) => !now.isBefore(startAt) && now.isBefore(endAt);

  Duration remaining(DateTime now) {
    if (!now.isBefore(endAt)) return Duration.zero;
    return endAt.difference(now);
  }

  int daysRemaining(DateTime now) {
    final duration = remaining(now);
    if (duration == Duration.zero) return 0;
    return (duration.inHours / 24).ceil().clamp(0, 999).toInt();
  }

  String countdownLabel(DateTime now) {
    final days = daysRemaining(now);
    if (days <= 0) return 'Ended';
    if (days == 1) return 'Ends tomorrow';
    return 'Ends in $days days';
  }

  String urgencyLabel(DateTime now) {
    final days = daysRemaining(now);
    if (days <= 1) return 'Last chance tomorrow';
    if (days <= 2) return 'Leaving soon';
    return 'Featured reward set';
  }

  List<CosmeticItem> resolveItems(List<CosmeticItem> catalog) {
    final byId = {for (final item in catalog) item.id: item};
    return itemIds.map((id) => byId[id]).whereType<CosmeticItem>().toList();
  }

  CosmeticItem? resolveHeadline(List<CosmeticItem> catalog) {
    for (final item in catalog) {
      if (item.id == headlineItemId) return item;
    }
    return null;
  }

  factory WeeklyFeaturedCosmeticSet.fromJson(Map<String, dynamic> json) {
    final rawItemIds = json['itemIds'] ?? json['item_ids'];
    return WeeklyFeaturedCosmeticSet(
      rotationId: _asString(json['rotationId'] ?? json['rotation_id']),
      title: _asString(json['title'], fallback: 'FEATURED WEEK'),
      startAt:
          DateTime.tryParse(_asString(json['startAt'] ?? json['start_at'])) ??
          DateTime.now(),
      endAt:
          DateTime.tryParse(_asString(json['endAt'] ?? json['end_at'])) ??
          DateTime.now().add(const Duration(days: 7)),
      headlineItemId: _asString(
        json['headlineItemId'] ?? json['headline_item_id'],
      ),
      itemIds: rawItemIds is List
          ? rawItemIds.map((entry) => entry.toString()).toList(growable: false)
          : const <String>[],
      badgeName: _asString(json['badgeName'] ?? json['badge_name']),
      profileFlair: _asString(json['profileFlair'] ?? json['profile_flair']),
      leaderboardAccentLabel: _asString(
        json['leaderboardAccentLabel'] ?? json['leaderboard_accent_label'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'rotationId': rotationId,
    'title': title,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
    'headlineItemId': headlineItemId,
    'itemIds': itemIds,
    'badgeName': badgeName,
    'profileFlair': profileFlair,
    'leaderboardAccentLabel': leaderboardAccentLabel,
  };
}

class WeeklyFeaturedState {
  const WeeklyFeaturedState({
    required this.activeSet,
    this.completedRotationIds = const <String>[],
    this.updatedAt,
  });

  final WeeklyFeaturedCosmeticSet activeSet;
  final List<String> completedRotationIds;
  final DateTime? updatedAt;

  bool get isActiveSetCompleted =>
      completedRotationIds.contains(activeSet.rotationId);

  WeeklyFeaturedState copyWith({
    WeeklyFeaturedCosmeticSet? activeSet,
    List<String>? completedRotationIds,
    DateTime? updatedAt,
  }) {
    return WeeklyFeaturedState(
      activeSet: activeSet ?? this.activeSet,
      completedRotationIds: completedRotationIds ?? this.completedRotationIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WeeklyFeaturedState.fromJson(Map<String, dynamic> json) {
    final rawSet = json['activeSet'] ?? json['active_set'];
    final rawCompleted =
        json['completedRotationIds'] ?? json['completed_rotation_ids'];
    return WeeklyFeaturedState(
      activeSet: rawSet is Map
          ? WeeklyFeaturedCosmeticSet.fromJson(
              Map<String, dynamic>.from(rawSet),
            )
          : WeeklyFeaturedRotationCatalog.currentSet(),
      completedRotationIds: rawCompleted is List
          ? rawCompleted
                .map((entry) => entry.toString())
                .toList(growable: false)
          : const <String>[],
      updatedAt: DateTime.tryParse(
        _asString(json['updatedAt'] ?? json['updated_at']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'activeSet': activeSet.toJson(),
    'completedRotationIds': completedRotationIds,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

class WeeklyFeaturedRotationCatalog {
  const WeeklyFeaturedRotationCatalog._();

  static WeeklyFeaturedCosmeticSet currentSet({DateTime? now}) {
    final current = now ?? DateTime.now();
    final weekStart = _weekStart(current);
    final weekIndex = _weekIndex(weekStart);
    final template = _templates[weekIndex % _templates.length];
    return template.build(weekStart);
  }

  static DateTime _weekStart(DateTime value) {
    final localDate = DateTime(value.year, value.month, value.day);
    return localDate.subtract(Duration(days: localDate.weekday - 1));
  }

  static int _weekIndex(DateTime weekStart) {
    final epoch = DateTime(2026, 1, 5);
    return weekStart.difference(epoch).inDays ~/ 7;
  }

  static final List<_WeeklyFeaturedTemplate> _templates = [
    _WeeklyFeaturedTemplate(
      slug: 'comet',
      title: 'COMET WEEK',
      headlineItemId: 'frame_comet',
      itemIds: const [
        'frame_comet',
        'effect_nova_trail',
        'effect_neon_number_burst',
      ],
      badgeName: 'Comet Week Complete',
      profileFlair: 'Comet Week Complete',
      leaderboardAccentLabel: 'Comet Week Complete',
    ),
    _WeeklyFeaturedTemplate(
      slug: 'nova',
      title: 'NOVA WEEK',
      headlineItemId: 'effect_nova_trail',
      itemIds: const [
        'effect_nova_trail',
        'frame_comet',
        'effect_neon_number_burst',
        'frame_blue_glow',
      ],
      badgeName: 'Nova Week Complete',
      profileFlair: 'Nova Week Complete',
      leaderboardAccentLabel: 'Nova Week Complete',
    ),
  ];
}

class _WeeklyFeaturedTemplate {
  const _WeeklyFeaturedTemplate({
    required this.slug,
    required this.title,
    required this.headlineItemId,
    required this.itemIds,
    required this.badgeName,
    required this.profileFlair,
    required this.leaderboardAccentLabel,
  });

  final String slug;
  final String title;
  final String headlineItemId;
  final List<String> itemIds;
  final String badgeName;
  final String profileFlair;
  final String leaderboardAccentLabel;

  WeeklyFeaturedCosmeticSet build(DateTime weekStart) {
    final dateId =
        '${weekStart.year}${weekStart.month.toString().padLeft(2, '0')}${weekStart.day.toString().padLeft(2, '0')}';
    return WeeklyFeaturedCosmeticSet(
      rotationId: '$slug-$dateId',
      title: title,
      startAt: weekStart,
      endAt: weekStart.add(const Duration(days: 7)),
      headlineItemId: headlineItemId,
      itemIds: itemIds,
      badgeName: badgeName,
      profileFlair: profileFlair,
      leaderboardAccentLabel: leaderboardAccentLabel,
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final safe = value?.toString().trim();
  if (safe == null || safe.isEmpty) return fallback;
  return safe;
}
