import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'network/dio_factory.dart';

class ProgressApiService {
  ProgressApiService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  final Dio _dio;

  Future<ApiResult<Map<String, dynamic>>> fetchOverviewResult() async {
    try {
      final response = await _dio.get('/api/progress/overview');
      if (response.data is Map<String, dynamic>) {
        return ApiResult.success(
          response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      }
      if (response.data is Map) {
        return ApiResult.success(
          Map<String, dynamic>.from(response.data as Map),
          statusCode: response.statusCode,
        );
      }
      return ApiResult.failure(
        ApiError(
          message: 'Unexpected /api/progress/overview payload type',
          statusCode: response.statusCode,
          errorCode: 'invalid_payload',
        ),
      );
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    } catch (e, st) {
      debugPrint('[ProgressApiService] fetchOverview failed: $e');
      return ApiResult.failure(ApiError(message: e.toString(), stackTrace: st));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> fetchWeekActivityResult() async {
    try {
      final response = await _dio.get('/api/progress/week-activity');
      if (response.data is Map<String, dynamic>) {
        return ApiResult.success(
          response.data as Map<String, dynamic>,
          statusCode: response.statusCode,
        );
      }
      if (response.data is Map) {
        return ApiResult.success(
          Map<String, dynamic>.from(response.data as Map),
          statusCode: response.statusCode,
        );
      }
      return ApiResult.failure(
        ApiError(
          message: 'Unexpected /api/progress/week-activity payload type',
          statusCode: response.statusCode,
          errorCode: 'invalid_payload',
        ),
      );
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    } catch (e, st) {
      debugPrint('[ProgressApiService] fetchWeekActivity failed: $e');
      return ApiResult.failure(ApiError(message: e.toString(), stackTrace: st));
    }
  }

  Future<ApiResult<bool>> syncProgressResult(
    Map<String, dynamic> progress,
  ) async {
    try {
      final response = await _dio.post('/api/progress/sync', data: progress);
      final statusCode = response.statusCode;
      final ok = statusCode != null && statusCode >= 200 && statusCode < 300;
      if (ok) {
        return ApiResult.success(true, statusCode: statusCode);
      }
      return ApiResult.failure(
        ApiError(
          message: 'Progress sync failed',
          statusCode: statusCode,
          errorCode: 'sync_failed',
        ),
      );
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    } catch (e, st) {
      debugPrint('[ProgressApiService] syncProgress failed: $e');
      return ApiResult.failure(ApiError(message: e.toString(), stackTrace: st));
    }
  }

  @Deprecated('Use fetchOverviewResult() to preserve error details.')
  Future<Map<String, dynamic>?> fetchOverview() async =>
      (await fetchOverviewResult()).data;

  @Deprecated('Use fetchWeekActivityResult() to preserve error details.')
  Future<Map<String, dynamic>?> fetchWeekActivity() async =>
      (await fetchWeekActivityResult()).data;

  @Deprecated('Use syncProgressResult() to preserve error details.')
  Future<bool> syncProgress(Map<String, dynamic> progress) async =>
      (await syncProgressResult(progress)).isSuccess;
}
