import 'adaptive_learning_path.dart';

class PracticeRecommendation {
  const PracticeRecommendation({
    required this.topicId,
    required this.topicName,
    required this.reason,
    required this.priorityScore,
    required this.recommendedDifficulty,
    required this.practiceId,
  });

  final int topicId;
  final String topicName;
  final String reason;
  final double priorityScore;
  final SkillDifficulty recommendedDifficulty;
  final String practiceId;

  factory PracticeRecommendation.fromJson(Map<String, dynamic> json) {
    return PracticeRecommendation(
      topicId: _asInt(json['topicId']) ?? 0,
      topicName: (json['topicName'] ?? json['topic'] ?? 'Practice').toString(),
      reason: (json['reason'] ?? 'continue').toString(),
      priorityScore: _asDouble(json['priorityScore']) ?? 0,
      recommendedDifficulty: parseSkillDifficulty(
        json['recommendedDifficulty']?.toString(),
      ),
      practiceId: (json['practiceId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'reason': reason,
      'priorityScore': priorityScore,
      'recommendedDifficulty': recommendedDifficulty.label,
      'practiceId': practiceId,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
