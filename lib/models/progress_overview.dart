class ProgressOverview {
  final int totalQuizzes;
  final int completedQuizzes;
  final double averageScore;
  final double bestScore;
  final DateTime lastQuizDate;

  ProgressOverview({
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.averageScore,
    required this.bestScore,
    required this.lastQuizDate,
  });

  factory ProgressOverview.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double asDouble(dynamic value, {double fallback = 0}) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    // Backend currently returns: totalAnswered, accuracy, dailyStreak, ...
    final totalAnswered = asInt(json['totalAnswered'] ?? json['totalAttempts']);
    final accuracyPct = asDouble(json['accuracy']) / 100.0;

    return ProgressOverview(
      totalQuizzes: asInt(json['totalQuizzes'], fallback: totalAnswered),
      completedQuizzes: asInt(
        json['completedQuizzes'],
        fallback: totalAnswered,
      ),
      averageScore: asDouble(json['averageScore'], fallback: accuracyPct),
      bestScore: asDouble(json['bestScore'], fallback: accuracyPct),
      lastQuizDate: parseDate(
        json['lastQuizDate'] ?? json['lastActivityDay'] ?? json['lastStreakDay'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalQuizzes': totalQuizzes,
      'completedQuizzes': completedQuizzes,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'lastQuizDate': lastQuizDate.toIso8601String(),
    };
  }
}
