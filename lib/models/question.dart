import 'option.dart';

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
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      options: (json['options'] as List)
          .map((optionJson) => Option.fromJson(optionJson))
          .toList(),
      correctAnswerId: json['correctAnswerId'],
      subtopicId: json['subtopicId'],
      hintLight: json['hintLight'],
      hintMedium: json['hintMedium'],
      hintFull: json['hintFull'],
      explanation: json['explanation'],
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
    };
  }
}