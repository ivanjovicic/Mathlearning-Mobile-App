class SchoolAggregateItem {
  final int rank;
  final int schoolId;
  final String schoolName;
  final int score;
  final int members;
  final String? logoUrl;
  final double? averageXp;
  final int? activeStudents;
  final int? studentsCount;
  final double? weightedScore;
  final int? rankDelta;
  final String? leagueTier;
  final String? city;
  final String? country;
  final DateTime? updatedAt;

  SchoolAggregateItem({
    required this.rank,
    required this.schoolId,
    required this.schoolName,
    required this.score,
    required this.members,
    this.logoUrl,
    this.averageXp,
    this.activeStudents,
    this.studentsCount,
    this.weightedScore,
    this.rankDelta,
    this.leagueTier,
    this.city,
    this.country,
    this.updatedAt,
  });

  factory SchoolAggregateItem.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    final schoolName = (json['schoolName'] ?? json['name'] ?? '') as String;

    return SchoolAggregateItem(
      rank: asInt(json['rank']),
      schoolId: asInt(json['schoolId'], fallback: schoolName.hashCode.abs()),
      schoolName: schoolName,
      score: asInt(
        json['score'] ??
            json['xp'] ??
            json['weeklyXp'] ??
            json['xpTotal'] ??
            json['xp_total'],
      ),
      members: asInt(
        json['members'] ??
            json['studentCount'] ??
            json['student_count'] ??
            json['studentsCount'] ??
            json['students_count'],
      ),
      logoUrl: json['logoUrl'] as String?,
      averageXp: asDouble(json['averageXp'] ?? json['average_xp']),
      activeStudents: asInt(
        json['activeStudents'] ?? json['active_students'],
        fallback: -1,
      ).letNullIfNegative(),
      studentsCount: asInt(
        json['studentsCount'] ?? json['students_count'],
        fallback: -1,
      ).letNullIfNegative(),
      weightedScore: asDouble(json['weightedScore'] ?? json['weighted_score']),
      rankDelta: asInt(
        json['rankDelta'] ?? json['rank_delta'],
        fallback: -999999,
      ).letNullIfSentinel(),
      leagueTier: (json['leagueTier'] ?? json['league_tier'])?.toString(),
      city: (json['city'])?.toString(),
      country: (json['country'])?.toString(),
      updatedAt: DateTime.tryParse(
        (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
      ),
    );
  }
}

class SchoolLeaderboardResponse {
  final List<SchoolAggregateItem> items;
  final SchoolAggregateItem? mySchool;
  final String? nextCursor;

  SchoolLeaderboardResponse({
    required this.items,
    required this.mySchool,
    required this.nextCursor,
  });

  factory SchoolLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final rawItems =
        (json['items'] ?? json['entries']) as List? ?? const <dynamic>[];

    return SchoolLeaderboardResponse(
      items: rawItems
          .map((e) => SchoolAggregateItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      mySchool: json['mySchool'] == null
          ? null
          : SchoolAggregateItem.fromJson(
              json['mySchool'] as Map<String, dynamic>,
            ),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class SchoolPagingController {
  bool isLoading = false;
  bool hasMore = true;
  bool hasLoadedOnce = false;
  String? cursor;
  final List<SchoolAggregateItem> items = [];

  void reset() {
    isLoading = false;
    hasMore = true;
    hasLoadedOnce = false;
    cursor = null;
    items.clear();
  }
}

class SchoolLeaderboardHistoryPoint {
  final DateTime snapshotAt;
  final int rank;
  final int? score;
  final double? weightedScore;

  const SchoolLeaderboardHistoryPoint({
    required this.snapshotAt,
    required this.rank,
    this.score,
    this.weightedScore,
  });

  factory SchoolLeaderboardHistoryPoint.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return SchoolLeaderboardHistoryPoint(
      snapshotAt:
          DateTime.tryParse(
            (json['snapshotAt'] ?? json['snapshot_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      rank: asInt(json['rank']),
      score: asInt(json['score'], fallback: -1).letNullIfNegative(),
      weightedScore: asDouble(json['weightedScore'] ?? json['weighted_score']),
    );
  }
}

class SchoolLeaderboardDetail {
  final SchoolAggregateItem school;
  final List<SchoolLeaderboardHistoryPoint> history;

  const SchoolLeaderboardDetail({
    required this.school,
    this.history = const [],
  });

  factory SchoolLeaderboardDetail.fromJson(Map<String, dynamic> json) {
    final schoolJson = json['school'] is Map<String, dynamic>
        ? json['school'] as Map<String, dynamic>
        : json;
    final historyRaw = json['history'];
    final history = historyRaw is List
        ? historyRaw
              .whereType<Map>()
              .map(
                (item) => SchoolLeaderboardHistoryPoint.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : const <SchoolLeaderboardHistoryPoint>[];

    return SchoolLeaderboardDetail(
      school: SchoolAggregateItem.fromJson(schoolJson),
      history: history,
    );
  }
}

extension _NullableIntX on int {
  int? letNullIfNegative() => this < 0 ? null : this;

  int? letNullIfSentinel() => this == -999999 ? null : this;
}
