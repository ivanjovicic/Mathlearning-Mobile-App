import 'package:dio/dio.dart';

import 'api_service.dart';
import 'network/dio_factory.dart';

class AdaptiveContentApiService {
  AdaptiveContentApiService({Dio? dio}) : _dio = dio ?? DioFactory.create();

  final Dio _dio;

  Future<ApiResult<T>> _requestResult<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) mapper,
  ) async {
    try {
      final response = await request();
      return ApiResult.success(mapper(response.data), statusCode: response.statusCode);
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    } catch (e, st) {
      return ApiResult.failure(ApiError(message: e.toString(), stackTrace: st));
    }
  }

  Future<Map<String, dynamic>?> getAdaptivePath() async {
    final result = await getAdaptivePathResult();
    return result.data;
  }

  Future<ApiResult<Map<String, dynamic>>> getAdaptivePathResult() {
    return _requestResult<Map<String, dynamic>>(
      () => _dio.get('/api/adaptive/path'),
      (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> getAdaptivePathForUserResult(
    String userId,
  ) {
    return _requestResult<Map<String, dynamic>>(
      () => _dio.get('/api/adaptive/path'),
      (data) {
        if (data is Map<String, dynamic>) {
          if (data['data'] is Map<String, dynamic>) {
            return data['data'] as Map<String, dynamic>;
          }
          return data;
        }
        return <String, dynamic>{};
      },
    );
  }

  Future<Map<String, dynamic>?> getAdaptiveRecommendations() async {
    final result = await getAdaptiveRecommendationsResult();
    return result.data;
  }

  Future<ApiResult<Map<String, dynamic>>> getAdaptiveRecommendationsResult() {
    return _requestResult<Map<String, dynamic>>(
      () => _dio.get('/api/adaptive/recommendations'),
      (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is List &&
            data.isNotEmpty &&
            data.first is Map<String, dynamic>) {
          return data.first as Map<String, dynamic>;
        }
        return <String, dynamic>{};
      },
    );
  }

  Future<List<Map<String, dynamic>>?> getAdaptiveReview() async {
    final result = await getAdaptiveReviewResult();
    return result.data;
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getAdaptiveReviewResult() {
    return _requestResult<List<Map<String, dynamic>>>(
      () => _dio.get('/api/adaptive/reviews/due'),
      (data) {
        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList(growable: false);
        }
        if (data is Map<String, dynamic> && data['items'] is List) {
          return (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }
        if (data is Map<String, dynamic> && data['data'] is List) {
          return (data['data'] as List)
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }
        return const <Map<String, dynamic>>[];
      },
    );
  }
}
