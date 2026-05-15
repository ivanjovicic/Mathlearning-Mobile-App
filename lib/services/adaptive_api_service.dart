import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'network/dio_factory.dart';

class AdaptiveApiService {
  AdaptiveApiService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  final Dio _dio;

  Future<Map<String, dynamic>?> fetchAdaptivePath() async {
    try {
      final response = await _dio.get('/api/adaptive/path');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      debugPrint('[AdaptiveApiService] fetchAdaptivePath failed: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> fetchAdaptiveReviewDue() async {
    try {
      final response = await _dio.get('/api/adaptive/reviews/due');
      if (response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>)['items'] is List) {
        return ((response.data as Map<String, dynamic>)['items'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
    } catch (e) {
      debugPrint('[AdaptiveApiService] fetchAdaptiveReviewDue failed: $e');
    }
    return null;
  }

  Future<ApiResult<Map<String, dynamic>>> startPracticeSession(
    Map<String, dynamic> payload,
  ) {
    return ApiService().startPracticeSessionResult(payload);
  }

  Future<ApiResult<Map<String, dynamic>>> submitPracticeSessionAnswer(
    String sessionId,
    Map<String, dynamic> payload,
  ) {
    return ApiService().submitPracticeSessionAnswerResult(sessionId, payload);
  }

  Future<ApiResult<Map<String, dynamic>>> completePracticeSession(
    String sessionId,
  ) {
    return ApiService().completePracticeSessionResult(sessionId);
  }
}
