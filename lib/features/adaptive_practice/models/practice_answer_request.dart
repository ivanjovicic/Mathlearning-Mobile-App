class PracticeAnswerRequest {
  const PracticeAnswerRequest({
    required this.questionId,
    required this.selectedOption,
    required this.timeSpentMs,
  });

  final int questionId;
  final String selectedOption;
  final int timeSpentMs;

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedOption': selectedOption,
      'timeSpentMs': timeSpentMs,
    };
  }
}
