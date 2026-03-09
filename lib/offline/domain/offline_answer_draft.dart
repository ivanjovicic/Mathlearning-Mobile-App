class OfflineAnswerDraft {
  const OfflineAnswerDraft({
    required this.userId,
    required this.quizId,
    required this.questionId,
    required this.selectedAnswer,
    required this.timeSpentSeconds,
    required this.isCorrect,
    required this.answeredAt,
    required this.idempotencyKey,
  });

  final String userId;
  final String quizId;
  final int questionId;
  final String selectedAnswer;
  final int timeSpentSeconds;
  final bool isCorrect;
  final DateTime answeredAt;
  final String idempotencyKey;
}
