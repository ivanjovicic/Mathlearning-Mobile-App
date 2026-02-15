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
    return SchoolAggregateItem(
      rank: (json['rank'] as num).toInt(),
      schoolId: (json['schoolId'] as num).toInt(),
      schoolName: (json['schoolName'] ?? '') as String,
      score: (json['score'] as num).toInt(),
      members: (json['members'] as num).toInt(),
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
    return SchoolLeaderboardResponse(
      items: ((json['items'] as List?) ?? const <dynamic>[])
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

