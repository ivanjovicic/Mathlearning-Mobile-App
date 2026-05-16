import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_recommendation.dart';
import 'package:mathlearning/features/learning_map/models/skill_mastery.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/services/adaptive_content_api_service.dart';

abstract class LearningMapDataSource {
  Future<ApiResult<AdaptiveLearningPath>> fetchPath(String userId);

  Future<ApiResult<List<SkillMastery>>> fetchMastery(String userId);

  Future<ApiResult<List<SkillMastery>>> fetchWeakness(String userId);

  Future<ApiResult<List<PracticeRecommendation>>> fetchRecommendations(
    String userId,
  );
}

class LearningMapService implements LearningMapDataSource {
  LearningMapService({ApiService? apiService})
    : _api = apiService ?? ApiService(),
      _adaptiveApi = AdaptiveContentApiService();

  final ApiService _api;
  final AdaptiveContentApiService _adaptiveApi;

  @override
  Future<ApiResult<AdaptiveLearningPath>> fetchPath(String userId) async {
    final result = await _adaptiveApi.getAdaptivePathForUserResult(userId);
    if (result.data == null || result.error != null) {
      return _mapFailure(result);
    }

    try {
      return ApiResult(
        data: AdaptiveLearningPath.fromJson(result.data!),
        statusCode: result.statusCode,
      );
    } catch (error, stackTrace) {
      return ApiResult(
        error: ApiError(
          message: error.toString(),
          stackTrace: stackTrace,
          statusCode: result.statusCode,
        ),
      );
    }
  }

  @override
  Future<ApiResult<List<SkillMastery>>> fetchMastery(String userId) async {
    final result = await _api.getMasteryForUserResult(userId);
    return _mapMasteryResult(result);
  }

  @override
  Future<ApiResult<List<SkillMastery>>> fetchWeakness(String userId) async {
    final result = await _api.getWeaknessForUserResult(userId);
    return _mapMasteryResult(result);
  }

  @override
  Future<ApiResult<List<PracticeRecommendation>>> fetchRecommendations(
    String userId,
  ) async {
    final result = await _api.getPracticeRecommendationsForUserResult(userId);
    if (result.data == null || result.error != null) {
      return _mapFailure(result);
    }

    try {
      return ApiResult(
        data: result.data!
            .map(PracticeRecommendation.fromJson)
            .toList(growable: false),
        statusCode: result.statusCode,
      );
    } catch (error, stackTrace) {
      return ApiResult(
        error: ApiError(
          message: error.toString(),
          stackTrace: stackTrace,
          statusCode: result.statusCode,
        ),
      );
    }
  }

  ApiResult<List<SkillMastery>> _mapMasteryResult(
    ApiResult<List<Map<String, dynamic>>> result,
  ) {
    if (result.data == null || result.error != null) {
      return _mapFailure(result);
    }

    try {
      return ApiResult(
        data: result.data!.map(SkillMastery.fromJson).toList(growable: false),
        statusCode: result.statusCode,
      );
    } catch (error, stackTrace) {
      return ApiResult(
        error: ApiError(
          message: error.toString(),
          stackTrace: stackTrace,
          statusCode: result.statusCode,
        ),
      );
    }
  }

  ApiResult<T> _mapFailure<T>(ApiResult<dynamic> result) {
    return ApiResult<T>(
      error: result.error,
      statusCode: result.statusCode,
      errorCode: result.errorCode,
      isRateLimited: result.isRateLimited,
      retryAfter: result.retryAfter,
      isOffline: result.isOffline,
      isAuthError: result.isAuthError,
    );
  }
}
