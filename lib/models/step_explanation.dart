class StepExplanation {
  final String text;
  final String? hint;
  final bool highlight;

  const StepExplanation({
    required this.text,
    this.hint,
    this.highlight = false,
  });

  factory StepExplanation.fromJson(Map<String, dynamic> json) {
    final text = (json['text'] ?? json['Text'] ?? '').toString();
    return StepExplanation(
      text: text,
      hint: (json['hint'] ?? json['Hint'])?.toString(),
      highlight:
          json['highlight'] == true ||
          json['Highlight'] == true ||
          json['highlight'] == 1 ||
          json['Highlight'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'hint': hint,
      'highlight': highlight,
    };
  }
}
