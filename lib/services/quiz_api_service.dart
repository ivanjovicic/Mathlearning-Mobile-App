import 'package:dio/dio.dart';

import 'network/dio_factory.dart';

class ApiRateLimitedException implements Exception {
  final Duration? retryAfter;
  ApiRateLimitedException([this.retryAfter]);

  @override
  String toString() => 'ApiRateLimitedException(retryAfter: $retryAfter)';
}

class QuizApiService {
  final Dio _dio;

  QuizApiService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  List<Map<String, dynamic>> _parseQuestionList(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>?> getQuestions(
    String topicKey,
    int count,
  ) async {
    try {
      final resp = await _dio.get(
        '/api/quiz/questions',
        queryParameters: {'topic': topicKey, 'count': count},
      );
      if (resp.data is List) {
        final parsed = _parseQuestionList(resp.data);
        return parsed.isEmpty ? null : parsed;
      }
      if (resp.data is Map && resp.data['questions'] is List) {
        final parsed = _parseQuestionList(resp.data['questions']);
        return parsed.isEmpty ? null : parsed;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> submitAnswer(
    String quizId,
    int questionId,
    String answer,
    int timeSpentSeconds, [
    String? token,
  ]) async {
    try {
      final resp = await _dio.post(
        '/api/quiz/answer',
        data: {
          'quizId': quizId,
          'questionId': questionId,
          'answer': answer,
          'timeSpentSeconds': timeSpentSeconds,
        },
      );
      return resp.data as Map<String, dynamic>?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        final retryHeader = e.response?.headers.value('retry-after');
        final retryAfter = retryHeader != null
            ? Duration(seconds: int.tryParse(retryHeader) ?? 0)
            : null;
        throw ApiRateLimitedException(retryAfter);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
