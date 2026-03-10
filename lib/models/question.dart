import 'option.dart';
import 'step_explanation.dart';
import '../widgets/math/math_content_parser.dart';

class Question {
  final int id;
  final String text;
  final List<Option> options;
  final int correctAnswerId;
  final int? subtopicId;
  final String? hintLight;
  final String? hintMedium;
  final String? hintFull;
  final String? explanation;
  final List<StepExplanation> steps;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerId,
    this.subtopicId,
    this.hintLight,
    this.hintMedium,
    this.hintFull,
    this.explanation,
    this.steps = const [],
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'];
    final parsedOptions = optionsRaw is List
        ? optionsRaw
              .whereType<Map>()
              .map(
                (optionJson) =>
                    Option.fromJson(Map<String, dynamic>.from(optionJson)),
              )
              .toList()
        : <Option>[];

    final stepsRaw = json['steps'] ?? json['Steps'];
    final parsedSteps = stepsRaw is List
        ? stepsRaw
              .map((stepJson) {
                if (stepJson is Map) {
                  return StepExplanation.fromJson(
                    Map<String, dynamic>.from(stepJson),
                  );
                }
                return StepExplanation(text: stepJson.toString());
              })
              .where((step) => step.text.trim().isNotEmpty)
              .toList()
        : <StepExplanation>[];

    final fallbackText = _buildFallbackText(json);
    final rawText =
        json['text'] ?? json['Text'] ?? json['questionText'] ?? json['question'];
    final parsedText = _sanitizeContent(rawText);

    return Question(
      id: _asInt(json['id']) ?? _asInt(json['Id']) ?? 0,
      text: parsedText.isNotEmpty ? parsedText : fallbackText,
      options: parsedOptions,
      correctAnswerId:
          _asInt(json['correctAnswerId']) ??
          _asInt(json['correctAnswer']) ??
          _resolveCorrectAnswerId(json, parsedOptions),
      subtopicId: _asInt(json['subtopicId']) ?? _asInt(json['SubtopicId']),
      hintLight: _sanitizeNullableContent(json['hintLight'] ?? json['hint_light']),
      hintMedium: _sanitizeNullableContent(
        json['hintMedium'] ?? json['hint_medium'],
      ),
      hintFull: _sanitizeNullableContent(json['hintFull'] ?? json['hint_full']),
      explanation: _sanitizeNullableContent(json['explanation']),
      steps: parsedSteps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options.map((option) => option.toJson()).toList(),
      'correctAnswerId': correctAnswerId,
      'subtopicId': subtopicId,
      'hintLight': hintLight,
      'hintMedium': hintMedium,
      'hintFull': hintFull,
      'explanation': explanation,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int _resolveCorrectAnswerId(
    Map<String, dynamic> json,
    List<Option> options,
  ) {
    final raw = json['correctAnswer'] ?? json['CorrectAnswer'];
    if (raw is num) return raw.toInt();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
      for (final option in options) {
        if (option.text.trim() == raw.trim()) {
          return option.id;
        }
      }
    }
    return options.isNotEmpty ? options.first.id : 0;
  }

  static String _buildFallbackText(Map<String, dynamic> json) {
    final type = (json['type'] ?? json['Type'])?.toString();
    final a = (json['a'] ?? json['A'])?.toString();
    final b = (json['b'] ?? json['B'])?.toString();
    if (a == null || b == null || type == null) {
      return 'Question';
    }

    switch (type.toLowerCase()) {
      case 'addition':
      case 'add':
        return '$a + $b = ?';
      case 'subtraction':
      case 'subtract':
        return '$a - $b = ?';
      case 'multiplication':
      case 'multiply':
        return '$a * $b = ?';
      case 'division':
      case 'divide':
        return '$a / $b = ?';
      default:
        return '$a ? $b';
    }
  }

  static String _sanitizeContent(dynamic value) {
    return MathContentParser.normalizeInput((value ?? '').toString());
  }

  static String? _sanitizeNullableContent(dynamic value) {
    final normalized = _sanitizeContent(value);
    return normalized.isEmpty ? null : normalized;
  }
}
