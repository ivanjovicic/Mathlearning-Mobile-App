import 'package:mathlearning/models/question.dart';

class QuizResponse {
  final String quizId;
  final List<Question> questions;

  QuizResponse({required this.quizId, required this.questions});

  factory QuizResponse.fromJson(Map<String, dynamic> json) {
    return QuizResponse(
      quizId: json['quizId'],
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
    );
  }
}
