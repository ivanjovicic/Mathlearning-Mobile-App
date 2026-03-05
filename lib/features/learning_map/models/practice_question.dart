class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctOptionId,
    this.hint,
  });

  final int id;
  final String prompt;
  final List<PracticeOption> options;
  final int correctOptionId;
  final String? hint;

  bool isCorrect(int optionId) => optionId == correctOptionId;
}

class PracticeOption {
  const PracticeOption({required this.id, required this.label});

  final int id;
  final String label;
}
