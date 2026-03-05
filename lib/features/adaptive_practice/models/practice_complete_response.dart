import 'package:mathlearning/features/adaptive_practice/models/practice_parsing.dart';

class PracticeCompleteResponse {
  const PracticeCompleteResponse({
    required this.sessionId,
    required this.status,
    required this.answeredQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.xpEarned,
    required this.initialMastery,
    required this.finalMastery,
    required this.masteryDelta,
    required this.weakTopicsUpdated,
    required this.recommendedNextSkillNodeId,
  });

  final String sessionId;
  final String status;
  final int answeredQuestions;
  final int correctAnswers;
  final double accuracy;
  final int xpEarned;
  final double initialMastery;
  final double finalMastery;
  final double masteryDelta;
  final bool weakTopicsUpdated;
  final String? recommendedNextSkillNodeId;

  factory PracticeCompleteResponse.fromJson(Map<String, dynamic> json) {
    final nextNodeId = asString(json['recommendedNextSkillNodeId']);
    return PracticeCompleteResponse(
      sessionId: asString(json['sessionId']),
      status: asString(json['status'], 'Completed'),
      answeredQuestions: asInt(json['answeredQuestions']),
      correctAnswers: asInt(json['correctAnswers']),
      accuracy: asDouble(json['accuracy']),
      xpEarned: asInt(json['xpEarned']),
      initialMastery: asDouble(json['initialMastery']),
      finalMastery: asDouble(json['finalMastery']),
      masteryDelta: asDouble(json['masteryDelta']),
      weakTopicsUpdated: json['weakTopicsUpdated'] == true,
      recommendedNextSkillNodeId: nextNodeId.isEmpty ? null : nextNodeId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'status': status,
      'answeredQuestions': answeredQuestions,
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
      'xpEarned': xpEarned,
      'initialMastery': initialMastery,
      'finalMastery': finalMastery,
      'masteryDelta': masteryDelta,
      'weakTopicsUpdated': weakTopicsUpdated,
      'recommendedNextSkillNodeId': recommendedNextSkillNodeId,
    };
  }
}
