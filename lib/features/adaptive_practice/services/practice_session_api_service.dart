import 'dart:async';

import 'package:mathlearning/features/adaptive_practice/models/practice_answer_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_answer_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_response.dart';
import 'package:mathlearning/services/api_service.dart';

class PracticeSessionApiService {
  PracticeSessionApiService({ApiService? apiService, this.maxAttempts = 2})
    : _api = apiService ?? ApiService();

  final ApiService _api;
  final int maxAttempts;

  Future<ApiResult<PracticeStartResponse>> startSession(
    PracticeStartRequest request,
  ) async {
    final result = await _runWithRateLimitRetry(
      () => _api.startPracticeSessionResult(request.toJson()),
    );
    return _mapResult(result, PracticeStartResponse.fromJson);
  }

  Future<ApiResult<PracticeAnswerResponse>> submitAnswer(
    String sessionId,
    PracticeAnswerRequest request,
  ) async {
    final result = await _runWithRateLimitRetry(
      () => _api.submitPracticeSessionAnswerResult(sessionId, request.toJson()),
    );
    return _mapResult(result, PracticeAnswerResponse.fromJson);
  }

  Future<ApiResult<PracticeCompleteResponse>> completeSession(
    String sessionId,
  ) async {
    final result = await _runWithRateLimitRetry(
      () => _api.completePracticeSessionResult(sessionId),
    );
    return _mapResult(result, PracticeCompleteResponse.fromJson);
  }

  Future<ApiResult<Map<String, dynamic>>> _runWithRateLimitRetry(
    Future<ApiResult<Map<String, dynamic>>> Function() request,
  ) async {
    var attempt = 0;
    ApiResult<Map<String, dynamic>> result = await request();

    while (result.isRateLimited && attempt < maxAttempts) {
      final wait = result.retryAfter ?? const Duration(seconds: 1);
      await Future<void>.delayed(wait);
      attempt += 1;
      result = await request();
    }

    return result;
  }

  ApiResult<T> _mapResult<T>(
    ApiResult<Map<String, dynamic>> result,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (result.data == null || result.error != null) {
      return ApiResult<T>(
        error: result.error,
        statusCode: result.statusCode,
        isRateLimited: result.isRateLimited,
        retryAfter: result.retryAfter,
      );
    }

    try {
      return ApiResult<T>(
        data: mapper(result.data!),
        statusCode: result.statusCode,
      );
    } catch (error, stackTrace) {
      return ApiResult<T>(
        error: ApiError(
          message: 'Failed to parse response: $error',
          stackTrace: stackTrace,
          statusCode: result.statusCode,
        ),
      );
    }
  }
}
