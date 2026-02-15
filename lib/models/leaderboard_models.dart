class LeaderboardItem {
  final int rank;
  final int userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final int streakDays;

  LeaderboardItem({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.streakDays,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      rank: (json['rank'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      displayName: (json['displayName'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      score: (json['score'] as num).toInt(),
      streakDays: (json['streakDays'] as num).toInt(),
    );
  }
}

class LeaderboardMe {
  final int rank;
  final int score;
  final int percentile;
  final List<String> badges;

  LeaderboardMe({
    required this.rank,
    required this.score,
    required this.percentile,
    required this.badges,
  });

  factory LeaderboardMe.fromJson(Map<String, dynamic> j) => LeaderboardMe(
        rank: (j['rank'] as num).toInt(),
        score: (j['score'] as num).toInt(),
        percentile: (j['percentile'] as num).toInt(),
        badges: ((j['badges'] as List?) ?? const <dynamic>[]).cast<String>(),
      );
}

class LeaderboardResponse {
  final List<LeaderboardItem> items;
  final LeaderboardMe? me;
  final String? nextCursor;

  LeaderboardResponse({
    required this.items,
    required this.me,
    required this.nextCursor,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      items: ((json['items'] as List?) ?? const <dynamic>[])
          .map((e) => LeaderboardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      me: json['me'] == null
          ? null
          : LeaderboardMe.fromJson(json['me'] as Map<String, dynamic>),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class LeaderboardPagingController {
  bool isLoading = false;
  bool hasMore = true;
  bool hasLoadedOnce = false;
  String? cursor;
  final List<LeaderboardItem> items = [];

  void reset() {
    isLoading = false;
    hasMore = true;
    hasLoadedOnce = false;
    cursor = null;
    items.clear();
  }
}

