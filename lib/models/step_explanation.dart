import '../widgets/math/math_content_parser.dart';

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
    final text = MathContentParser.normalizeInput(
      (json['text'] ?? json['Text'] ?? '').toString(),
    );
    final hint = MathContentParser.normalizeInput(
      (json['hint'] ?? json['Hint'] ?? '').toString(),
    );
    return StepExplanation(
      text: text,
      hint: hint.isEmpty ? null : hint,
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
