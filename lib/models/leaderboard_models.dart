import 'social_cosmetic_loadout.dart';

enum LeaderboardPeriod { allTime, week, month }

LeaderboardPeriod parseLeaderboardPeriod(String? value) {
  switch (value) {
    case 'allTime':
    case 'all_time':
    case 'all-time':
      return LeaderboardPeriod.allTime;
    case 'month':
    case 'monthly':
      return LeaderboardPeriod.month;
    case 'week':
    case 'weekly':
    default:
      return LeaderboardPeriod.week;
  }
}

extension LeaderboardPeriodX on LeaderboardPeriod {
  String get apiValue {
    switch (this) {
      case LeaderboardPeriod.allTime:
        return 'all_time';
      case LeaderboardPeriod.week:
        return 'week';
      case LeaderboardPeriod.month:
        return 'month';
    }
  }

  String get label {
    switch (this) {
      case LeaderboardPeriod.allTime:
        return 'All-time';
      case LeaderboardPeriod.week:
        return 'Week';
      case LeaderboardPeriod.month:
        return 'Month';
    }
  }

  String get semanticsLabel {
    switch (this) {
      case LeaderboardPeriod.allTime:
        return 'all time';
      case LeaderboardPeriod.week:
        return 'weekly';
      case LeaderboardPeriod.month:
        return 'monthly';
    }
  }

  String get legacyValue {
    switch (this) {
      case LeaderboardPeriod.allTime:
        return 'allTime';
      case LeaderboardPeriod.week:
        return 'weekly';
      case LeaderboardPeriod.month:
        return 'month';
    }
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  final safe = value?.toString().trim() ?? fallback;
  return safe.isEmpty ? fallback : safe;
}

String? _asNullableString(dynamic value) {
  final safe = value?.toString().trim();
  if (safe == null || safe.isEmpty) {
    return null;
  }
  return safe;
}

class LeaderboardItem {
  const LeaderboardItem({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.streakDays,
    this.cosmeticLoadout,
  });

  final int rank;
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int streakDays;
  final SocialCosmeticLoadout? cosmeticLoadout;

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      rank: _asInt(json['rank']),
      userId: _asInt(json['userId'] ?? json['id']),
      displayName: _asString(json['displayName'] ?? json['name']),
      avatarUrl: _asNullableString(json['avatarUrl'] ?? json['avatar']),
      score: _asInt(json['score'] ?? json['xp'] ?? json['weeklyXp']),
      streakDays: _asInt(json['streakDays'] ?? json['streak']),
      cosmeticLoadout: socialCosmeticLoadoutFromJson(json),
    );
  }

  LeaderboardItem copyWith({
    int? rank,
    int? userId,
    String? displayName,
    String? avatarUrl,
    int? score,
    int? streakDays,
    SocialCosmeticLoadout? cosmeticLoadout,
  }) {
    return LeaderboardItem(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      streakDays: streakDays ?? this.streakDays,
      cosmeticLoadout: cosmeticLoadout ?? this.cosmeticLoadout,
    );
  }
}

class RivalLeaderboardEntry extends LeaderboardItem {
  const RivalLeaderboardEntry({
    required super.rank,
    required super.userId,
    required super.displayName,
    super.avatarUrl,
    required super.score,
    required super.streakDays,
    super.cosmeticLoadout,
  });

  factory RivalLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final base = LeaderboardItem.fromJson(json);
    return RivalLeaderboardEntry(
      rank: base.rank,
      userId: base.userId,
      displayName: base.displayName,
      avatarUrl: base.avatarUrl,
      score: base.score,
      streakDays: base.streakDays,
      cosmeticLoadout: base.cosmeticLoadout,
    );
  }
}

class LeaderboardMe {
  const LeaderboardMe({
    required this.rank,
    required this.score,
    required this.percentile,
    required this.badges,
  });

  final int rank;
  final int score;
  final int percentile;
  final List<String> badges;

  factory LeaderboardMe.fromJson(Map<String, dynamic> j) => LeaderboardMe(
    rank: _asInt(j['rank']),
    score: _asInt(j['score']),
    percentile: _asInt(j['percentile']),
    badges: ((j['badges'] as List?) ?? const <dynamic>[]).cast<String>(),
  );
}

class LeaderboardResponse {
  const LeaderboardResponse({
    required this.items,
    required this.me,
    required this.nextCursor,
  });

  final List<LeaderboardItem> items;
  final LeaderboardMe? me;
  final String? nextCursor;

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['items'] ?? json['entries']) as List? ?? const <dynamic>[];

    return LeaderboardResponse(
      items: rawItems
          .whereType<Map>()
          .map(
            (entry) =>
                LeaderboardItem.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList(),
      me: json['me'] == null
          ? null
          : LeaderboardMe.fromJson(json['me'] as Map<String, dynamic>),
      nextCursor: _asNullableString(json['nextCursor']),
    );
  }
}

class SchoolLeaderboardEntry {
  const SchoolLeaderboardEntry({
    required this.rank,
    required this.schoolId,
    required this.schoolName,
    required this.totalScore,
    this.members = 0,
    this.badgeLabel,
    this.badgeUrl,
    this.topAvatars = const <SocialCosmeticLoadout>[],
  });

  final int rank;
  final int schoolId;
  final String schoolName;
  final int totalScore;
  final int members;
  final String? badgeLabel;
  final String? badgeUrl;
  final List<SocialCosmeticLoadout> topAvatars;

  factory SchoolLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final schoolName = _asString(json['schoolName'] ?? json['name']);
    return SchoolLeaderboardEntry(
      rank: _asInt(json['rank']),
      schoolId: _asInt(
        json['schoolId'] ?? json['id'],
        fallback: schoolName.hashCode.abs(),
      ),
      schoolName: schoolName,
      totalScore: _asInt(
        json['totalScore'] ??
            json['score'] ??
            json['xp'] ??
            json['weeklyXp'] ??
            json['xpTotal'] ??
            json['xp_total'],
      ),
      members: _asInt(
        json['members'] ??
            json['studentCount'] ??
            json['student_count'] ??
            json['studentsCount'],
      ),
      badgeLabel: _asNullableString(
        json['badgeLabel'] ?? json['badge'] ?? json['leagueTier'],
      ),
      badgeUrl: _asNullableString(
        json['badgeUrl'] ?? json['logoUrl'] ?? json['badge_url'],
      ),
      topAvatars: _schoolTopAvatarsFromJson(json),
    );
  }
}

List<SocialCosmeticLoadout> _schoolTopAvatarsFromJson(
  Map<String, dynamic> json,
) {
  final raw =
      json['topAvatars'] ??
      json['top_avatars'] ??
      json['topStudents'] ??
      json['top_students'];
  if (raw is! List) {
    return const <SocialCosmeticLoadout>[];
  }
  return raw
      .map((entry) {
        if (entry is Map) {
          final map = Map<String, dynamic>.from(entry);
          return socialCosmeticLoadoutFromJson(map) ??
              SocialCosmeticLoadout.fromJson(map);
        }
        return null;
      })
      .whereType<SocialCosmeticLoadout>()
      .toList(growable: false);
}

class SchoolLeaderboardFeed {
  const SchoolLeaderboardFeed({
    required this.items,
    required this.currentSchool,
    required this.nextCursor,
  });

  final List<SchoolLeaderboardEntry> items;
  final SchoolLeaderboardEntry? currentSchool;
  final String? nextCursor;

  factory SchoolLeaderboardFeed.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['items'] ?? json['entries']) as List? ?? const <dynamic>[];

    return SchoolLeaderboardFeed(
      items: rawItems
          .whereType<Map>()
          .map(
            (entry) => SchoolLeaderboardEntry.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(),
      currentSchool: json['mySchool'] == null
          ? null
          : SchoolLeaderboardEntry.fromJson(
              json['mySchool'] as Map<String, dynamic>,
            ),
      nextCursor: _asNullableString(json['nextCursor']),
    );
  }
}

class LeaderboardPagingController<T> {
  bool isLoading = false;
  bool hasMore = true;
  bool hasLoadedOnce = false;
  String? cursor;
  final List<T> items = <T>[];

  void reset() {
    isLoading = false;
    hasMore = true;
    hasLoadedOnce = false;
    cursor = null;
    items.clear();
  }
}
