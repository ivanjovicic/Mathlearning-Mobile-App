import 'adaptive_learning_path.dart';

enum PracticeSource { weak, recent, review }

class PracticeLaunchPlan {
  const PracticeLaunchPlan({
    required this.userId,
    required this.nodeId,
    required this.skillTitle,
    required this.topicId,
    required this.subtopicId,
    required this.difficulty,
    required this.source,
    required this.practiceId,
    this.targetQuestions = 10,
  });

  final String userId;
  final String nodeId;
  final String skillTitle;
  final int topicId;
  final int subtopicId;
  final SkillDifficulty difficulty;
  final PracticeSource source;
  final String practiceId;
  final int targetQuestions;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nodeId': nodeId,
      'skillTitle': skillTitle,
      'topicId': topicId,
      'subtopicId': subtopicId,
      'difficulty': difficulty.label,
      'source': source.name,
      'practiceId': practiceId,
      'targetQuestions': targetQuestions,
    };
  }

  factory PracticeLaunchPlan.fromJson(Map<String, dynamic> json) {
    return PracticeLaunchPlan(
      userId: (json['userId'] ?? '').toString(),
      nodeId: (json['nodeId'] ?? '').toString(),
      skillTitle: (json['skillTitle'] ?? 'Practice').toString(),
      topicId: _asInt(json['topicId']) ?? 0,
      subtopicId: _asInt(json['subtopicId']) ?? 0,
      difficulty: parseSkillDifficulty(json['difficulty']?.toString()),
      source: _parseSource(json['source']?.toString()),
      practiceId: (json['practiceId'] ?? '').toString(),
      targetQuestions: _asInt(json['targetQuestions']) ?? 10,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static PracticeSource _parseSource(String? value) {
    switch (value) {
      case 'weak':
        return PracticeSource.weak;
      case 'review':
        return PracticeSource.review;
      default:
        return PracticeSource.recent;
    }
  }
}
