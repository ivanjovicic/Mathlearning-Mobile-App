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
    return ProgressOverview(
      totalQuizzes: json['totalQuizzes'],
      completedQuizzes: json['completedQuizzes'],
      averageScore: json['averageScore'].toDouble(),
      bestScore: json['bestScore'].toDouble(),
      lastQuizDate: DateTime.parse(json['lastQuizDate']),
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