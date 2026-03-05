class SchoolAggregateItem {
  final int rank;
  final int schoolId;
  final String schoolName;
  final int score;
  final int members;
  final String? logoUrl;

  SchoolAggregateItem({
    required this.rank,
    required this.schoolId,
    required this.schoolName,
    required this.score,
    required this.members,
    this.logoUrl,
  });

  factory SchoolAggregateItem.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    final schoolName = (json['schoolName'] ?? json['name'] ?? '') as String;

    return SchoolAggregateItem(
      rank: asInt(json['rank']),
      schoolId: asInt(
        json['schoolId'],
        fallback: schoolName.hashCode.abs(),
      ),
      schoolName: schoolName,
      score: asInt(json['score'] ?? json['xp'] ?? json['weeklyXp']),
      members: asInt(json['members']),
      logoUrl: json['logoUrl'] as String?,
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
    final rawItems = (json['items'] ?? json['entries']) as List? ?? const <dynamic>[];

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

