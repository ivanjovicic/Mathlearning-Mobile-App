import 'package:mathlearning/features/adaptive_practice/models/practice_parsing.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_question.dart';

class PracticeAnswerResponse {
  const PracticeAnswerResponse({
    required this.isCorrect,
    required this.feedback,
    required this.masteryBefore,
    required this.masteryAfter,
    required this.xpEarned,
    required this.nextQuestion,
  });

  final bool isCorrect;
  final String feedback;
  final double masteryBefore;
  final double masteryAfter;
  final int xpEarned;
  final PracticeQuestion? nextQuestion;

  bool get hasNextQuestion => nextQuestion != null && nextQuestion!.isValid;

  factory PracticeAnswerResponse.fromJson(Map<String, dynamic> json) {
    final rawNext = json['nextQuestion'];
    return PracticeAnswerResponse(
      isCorrect: json['isCorrect'] == true,
      feedback: asString(
        json['feedback'],
        json['isCorrect'] == true ? 'Correct!' : 'Try again',
      ),
      masteryBefore: asDouble(json['masteryBefore']),
      masteryAfter: asDouble(json['masteryAfter']),
      xpEarned: asInt(json['xpEarned']),
      nextQuestion: rawNext is Map<String, dynamic>
          ? PracticeQuestion.fromJson(rawNext)
          : rawNext is Map
          ? PracticeQuestion.fromJson(Map<String, dynamic>.from(rawNext))
          : null,
    );
  }
}
