import 'dart:math';

import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/features/learning_map/models/practice_question.dart';
import 'package:mathlearning/services/api_service.dart';

abstract class PracticeRepository {
  Future<List<PracticeQuestion>> loadQuestions(
    PracticeLaunchPlan plan, {
    int count = 10,
  });
}

class ApiPracticeRepository implements PracticeRepository {
  ApiPracticeRepository({ApiService? apiService})
    : _api = apiService ?? ApiService();

  final ApiService _api;

  @override
  Future<List<PracticeQuestion>> loadQuestions(
    PracticeLaunchPlan plan, {
    int count = 10,
  }) async {
    final topicKey = _toTopicKey(plan.skillTitle);
    final payload = await _api.getQuestions(topicKey, count);
    if (payload == null || payload.isEmpty) {
      return _buildFallbackQuestions(plan, count);
    }

    final parsed = <PracticeQuestion>[];
    for (var i = 0; i < payload.length; i++) {
      final item = payload[i];
      final question = _mapQuestion(item, i);
      if (question != null) {
        parsed.add(question);
      }
    }

    if (parsed.isEmpty) {
      return _buildFallbackQuestions(plan, count);
    }

    return parsed;
  }

  PracticeQuestion? _mapQuestion(Map<String, dynamic> raw, int index) {
    final id = _asInt(raw['id'] ?? raw['questionId']) ?? index + 1;
    final prompt = (raw['text'] ?? raw['question'] ?? raw['prompt'] ?? '')
        .toString()
        .trim();
    if (prompt.isEmpty) {
      return null;
    }

    final optionsRaw = raw['options'];
    final options = <PracticeOption>[];
    if (optionsRaw is List) {
      for (var i = 0; i < optionsRaw.length; i++) {
        final option = optionsRaw[i];
        if (option is Map) {
          final optionId = _asInt(option['id']) ?? (i + 1);
          final label = (option['text'] ?? option['label'] ?? '').toString();
          if (label.trim().isEmpty) continue;
          options.add(PracticeOption(id: optionId, label: label));
        } else if (option is String) {
          options.add(PracticeOption(id: i + 1, label: option));
        }
      }
    }

    if (options.length < 2) {
      return null;
    }

    final correctOptionId =
        _asInt(raw['correctAnswerId']) ??
        _asInt(raw['correctAnswer']) ??
        options.first.id;
    return PracticeQuestion(
      id: id,
      prompt: prompt,
      options: options,
      correctOptionId: correctOptionId,
      hint: raw['hint']?.toString(),
    );
  }

  List<PracticeQuestion> _buildFallbackQuestions(
    PracticeLaunchPlan plan,
    int count,
  ) {
    final random = Random(plan.topicId + plan.subtopicId + count);
    final list = <PracticeQuestion>[];
    for (var i = 0; i < count; i++) {
      final a = random.nextInt(12) + 1;
      final b = random.nextInt(12) + 1;
      final answer = a + b;
      final options = <int>{
        answer,
        answer + 1,
        answer - 1,
        answer + 2,
      }.where((value) => value > 0).take(4).toList(growable: false);
      list.add(
        PracticeQuestion(
          id: i + 1,
          prompt: '$a + $b = ?',
          options: options
              .asMap()
              .entries
              .map(
                (entry) => PracticeOption(
                  id: entry.key + 1,
                  label: entry.value.toString(),
                ),
              )
              .toList(growable: false),
          correctOptionId: options.indexOf(answer) + 1,
          hint: 'Try splitting numbers into tens and ones.',
        ),
      );
    }
    return list;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _toTopicKey(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'practice';
    }
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return safe.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }
}
