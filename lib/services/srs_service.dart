import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class SrsService {
  static final SrsService instance = SrsService._internal();
  SrsService._internal();

  /// Fetch daily SRS questions that need review
  Future<List<Map<String, dynamic>>> fetchDailySrsQuestions() async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.get('/api/quiz/srs/daily');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }

      debugPrint('Failed to load SRS questions: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching SRS questions: $e');
      return [];
    }
  }

  /// Fetch mixed SRS questions (daily mix)
  Future<List<Map<String, dynamic>>> fetchMixedSrsQuestions() async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.get('/api/quiz/srs/mixed');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }

      debugPrint('Failed to load mixed SRS questions: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching mixed SRS questions: $e');
      return [];
    }
  }

  /// Fetch streak badge data
  Future<Map<String, dynamic>?> fetchStreakBadge() async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.get('/api/quiz/srs/streak');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        }
      }

      debugPrint('Failed to load streak badge: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching streak badge: $e');
      return null;
    }
  }

  /// Update SRS data after answering a question
  Future<bool> updateSrs({
    required int questionId,
    required bool isCorrect,
    required int timeMs,
  }) async {
    try {
      final dio = AuthService.instance.client;
      final response = await dio.post(
        '/api/quiz/srs/update',
        data: {
          "questionId": questionId,
          "isCorrect": isCorrect,
          "timeMs": timeMs,
        },
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        debugPrint('✅ SRS updated for question $questionId');
        return true;
      }

      debugPrint('⚠️ SRS update failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error updating SRS: $e');
      return false;
    }
  }
}
