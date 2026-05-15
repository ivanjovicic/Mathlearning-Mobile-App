import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'progress_api_service.dart';

/// Thin wrapper around the backend progress endpoints.
/// Uses the existing Dio auth interceptor so tokens are attached automatically.
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  final ProgressApiService _api = ProgressApiService();

  /// GET /api/progress/overview -> full progress map
  Future<ApiResult<Map<String, dynamic>>> fetchProgressResult() async {
    try {
      return await _api.fetchOverviewResult();
    } catch (e) {
      debugPrint('ProgressService.fetchProgress error: $e');
      return ApiResult.failure(
        ApiError(message: e.toString(), errorCode: 'progress_service_error'),
      );
    }
  }

  /// POST /api/progress/sync -> push local progress to server
  Future<ApiResult<bool>> pushProgressResult(
    Map<String, dynamic> progress,
  ) async {
    try {
      return await _api.syncProgressResult(progress);
    } catch (e) {
      debugPrint('ProgressService.pushProgress error: $e');
      return ApiResult.failure(
        ApiError(message: e.toString(), errorCode: 'progress_service_error'),
      );
    }
  }

  @Deprecated('Use fetchProgressResult() to preserve error details.')
  Future<Map<String, dynamic>?> fetchProgress() async =>
      (await fetchProgressResult()).data;

  @Deprecated('Use pushProgressResult() to preserve error details.')
  Future<bool> pushProgress(Map<String, dynamic> progress) async =>
      (await pushProgressResult(progress)).isSuccess;
}
