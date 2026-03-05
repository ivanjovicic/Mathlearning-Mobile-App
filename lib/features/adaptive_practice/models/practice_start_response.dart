import 'package:mathlearning/features/adaptive_practice/models/practice_difficulty.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_parsing.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_question.dart';

class PracticeStartResponse {
  const PracticeStartResponse({
    required this.sessionId,
    required this.skillNodeId,
    required this.recommendedDifficulty,
    required this.initialMastery,
    required this.question,
  });

  final String sessionId;
  final String skillNodeId;
  final PracticeDifficulty recommendedDifficulty;
  final double initialMastery;
  final PracticeQuestion? question;

  bool get hasQuestion => question != null && question!.isValid;

  factory PracticeStartResponse.fromJson(Map<String, dynamic> json) {
    final rawQuestion = json['question'];
    return PracticeStartResponse(
      sessionId: asString(json['sessionId']),
      skillNodeId: asString(json['skillNodeId']),
      recommendedDifficulty: parsePracticeDifficulty(
        json['recommendedDifficulty']?.toString(),
      ),
      initialMastery: asDouble(json['initialMastery']),
      question: rawQuestion is Map<String, dynamic>
          ? PracticeQuestion.fromJson(rawQuestion)
          : rawQuestion is Map
          ? PracticeQuestion.fromJson(Map<String, dynamic>.from(rawQuestion))
          : null,
    );
  }
}
