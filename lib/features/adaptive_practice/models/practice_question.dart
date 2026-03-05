import 'package:mathlearning/features/adaptive_practice/models/practice_difficulty.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_parsing.dart';

class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.difficulty,
  });

  final int id;
  final String prompt;
  final List<String> options;
  final PracticeDifficulty difficulty;

  bool get isValid => id > 0 && prompt.trim().isNotEmpty && options.length >= 2;

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
              .map((item) => asString(item))
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return PracticeQuestion(
      id: asInt(json['id']),
      prompt: asString(json['prompt'], 'Question unavailable'),
      options: options,
      difficulty: parsePracticeDifficulty(json['difficulty']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'options': options,
      'difficulty': difficulty.apiValue,
    };
  }
}
