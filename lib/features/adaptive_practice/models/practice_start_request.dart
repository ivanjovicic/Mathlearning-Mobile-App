import 'package:mathlearning/features/adaptive_practice/models/practice_difficulty.dart';

class PracticeStartRequest {
  const PracticeStartRequest({
    required this.skillNodeId,
    required this.topicId,
    required this.subtopicId,
    this.targetQuestions = 10,
    this.preferredDifficulty = PracticeDifficulty.medium,
  });

  final String skillNodeId;
  final int topicId;
  final int subtopicId;
  final int targetQuestions;
  final PracticeDifficulty preferredDifficulty;

  Map<String, dynamic> toJson() {
    return {
      'skillNodeId': skillNodeId,
      'topicId': topicId,
      'subtopicId': subtopicId,
      'targetQuestions': targetQuestions,
      'preferredDifficulty': preferredDifficulty.apiValue,
    };
  }
}
