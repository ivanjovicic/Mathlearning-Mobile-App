import 'dart:async';

import 'package:dio/dio.dart';
import '../models/progress_overview.dart';
import '../models/leaderboard_models.dart';
import '../models/school_leaderboard_models.dart';
import '../widgets/math/math_content_parser.dart';
import 'adaptive_content_api_service.dart';
import 'network/dio_factory.dart';
import 'leaderboard_api_service.dart';
import 'quiz_api_service.dart';

export 'quiz_api_service.dart';

// Models
class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final int? statusCode;
  final String? errorCode;
  final bool isRateLimited;
  final Duration? retryAfter;
  final bool isOffline;
  final bool isAuthError;

  ApiResult({
    this.data,
    this.error,
    this.statusCode,
    this.errorCode,
    this.isRateLimited = false,
    this.retryAfter,
    this.isOffline = false,
    this.isAuthError = false,
  });

  // isSuccess means request completed without ApiError; use hasData when payload is required.
  bool get isSuccess => error == null;

  bool get hasData => data != null && error == null;

  factory ApiResult.success(T data, {int? statusCode}) {
    return ApiResult<T>(data: data, statusCode: statusCode);
  }

  factory ApiResult.failure(ApiError error, {int? statusCode}) {
    return ApiResult<T>(
      error: error,
      statusCode: statusCode ?? error.statusCode,
      errorCode: error.errorCode,
      isRateLimited: (statusCode ?? error.statusCode) == 429,
      retryAfter: error.retryAfter,
      isOffline: error.isOffline,
      isAuthError: error.isAuthError,
    );
  }
}

class ApiError {
  final String message;
  final StackTrace? stackTrace;
  final DioExceptionType? dioErrorType;
  final int? statusCode;
  final String? errorCode;
  final Duration? retryAfter;
  final dynamic responseBody;
  final bool isOffline;
  final bool isAuthError;

  ApiError({
    required this.message,
    this.stackTrace,
    this.dioErrorType,
    this.statusCode,
    this.errorCode,
    this.retryAfter,
    this.responseBody,
    this.isOffline = false,
    this.isAuthError = false,
  });
}

// Utility for error parsing
ApiError parseError(DioException e) {
  final statusCode = e.response?.statusCode;
  final retryAfter = e.response?.headers.value('retry-after');
  final isOffline =
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      (e.type == DioExceptionType.unknown && e.response == null);
  return ApiError(
    message: e.message ?? e.toString(),
    stackTrace: e.stackTrace,
    dioErrorType: e.type,
    statusCode: statusCode,
    errorCode: _extractErrorCode(e.response?.data, statusCode),
    retryAfter: retryAfter != null
        ? Duration(seconds: int.tryParse(retryAfter) ?? 0)
        : null,
    responseBody: e.response?.data,
    isOffline: isOffline,
    isAuthError: statusCode == 401 || statusCode == 403,
  );
}

String? _extractErrorCode(dynamic responseBody, int? statusCode) {
  if (responseBody is Map) {
    final map = Map<String, dynamic>.from(responseBody);
    final code = map['errorCode'] ?? map['code'] ?? map['error_code'];
    if (code != null) {
      final value = code.toString().trim();
      if (value.isNotEmpty) return value;
    }
  }
  if (statusCode != null) {
    return 'http_$statusCode';
  }
  return null;
}

// Root API Client
class ApiClient {
  final AuthApi auth;
  final UserApi user;
  final ProgressApi progress;

  ApiClient(Dio dio)
    : auth = AuthApi(dio),
      user = UserApi(dio),
      progress = ProgressApi(dio);
}

// Auth API
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<ApiResult<bool>> authenticate(String username, String password) async {
    try {
      // Use /api/auth/login and capitalized keys to match dev backend
      final response = await _dio.post(
        '/api/auth/login',
        data: {'Username': username, 'Password': password},
      );
      return ApiResult(data: response.data['accessToken'] != null);
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> register(
    String username,
    String password,
    String email,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'username': username, 'password': password, 'email': email},
      );
      return ApiResult(data: response.data);
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    }
  }
}

// User API
class UserApi {
  final Dio _dio;

  UserApi(this._dio);

  Future<ApiResult<Map<String, dynamic>>> getUserProfile() async {
    try {
      final response = await _dio.get('/api/users/profile');
      return ApiResult(data: response.data);
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> getUserProfileById(
    String userId,
  ) async {
    try {
      final response = await _dio.get('/api/user/profile/$userId');
      return ApiResult(data: response.data);
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> updateUserProfile({
    String? displayName,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) {
        body['displayName'] = displayName;
      }
      if (email != null) {
        body['email'] = email;
      }
      final response = await _dio.put('/api/users/profile', data: body);
      return ApiResult(data: response.data);
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    }
  }
}

// Progress API
class ProgressApi {
  final Dio _dio;

  ProgressApi(this._dio);

  Future<ApiResult<ProgressOverview>> getProgressOverview() async {
    try {
      final response = await _dio.get('/api/progress/overview');
      return ApiResult(data: ProgressOverview.fromJson(response.data));
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    } catch (e, st) {
      return ApiResult.failure(ApiError(message: e.toString(), stackTrace: st));
    }
  }
}

// Utility for deduplication
class RequestDeduplicator {
  final Map<String, Future> _inFlightRequests = {};
  final int maxInFlight;

  RequestDeduplicator({this.maxInFlight = 100});

  Future<T> run<T>(String key, Future<T> Function() requestBuilder) {
    if (_inFlightRequests.length >= maxInFlight) {
      throw Exception('Too many in-flight requests');
    }

    final existing = _inFlightRequests[key];
    if (existing != null) {
      return existing as Future<T>;
    }

    final future = requestBuilder();
    _inFlightRequests[key] = future;
    future.whenComplete(() => _inFlightRequests.remove(key));
    return future;
  }
}

// Legacy compatibility: provide `ApiService` class expected by older callers.
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._() {
    _dio = DioFactory.create();
    _client = ApiClient(_dio);
  }

  late Dio _dio;
  late ApiClient _client;
  final QuizApiService _quizApi = QuizApiService();
  final LeaderboardApiService _leaderboardApi = LeaderboardApiService();
  final AdaptiveContentApiService _adaptiveContentApiService =
      AdaptiveContentApiService();

  Future<ApiResult<T>> _requestResult<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) mapper,
  ) async {
    try {
      final resp = await request();
      return ApiResult.success(mapper(resp.data), statusCode: resp.statusCode);
    } on DioException catch (e) {
      return ApiResult.failure(parseError(e));
    } catch (e, st) {
      return ApiResult.failure(ApiError(message: e.toString(), stackTrace: st));
    }
  }

  Future<ProgressOverview> getProgressOverview() async {
    final res = await _client.progress.getProgressOverview();
    if (res.data != null && res.error == null) return res.data!;
    return ProgressOverview(
      totalQuizzes: 0,
      completedQuizzes: 0,
      averageScore: 0.0,
      bestScore: 0.0,
      lastQuizDate: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final res = await _client.user.getUserProfile();
    return res.data;
  }

  Future<Map<String, dynamic>?> getUserProfileById(String userId) async {
    final res = await _client.user.getUserProfileById(userId);
    return res.data;
  }

  Future<Map<String, dynamic>?> updateUserProfile({
    String? displayName,
    String? email,
  }) async {
    final res = await _client.user.updateUserProfile(
      displayName: displayName,
      email: email,
    );
    return res.data;
  }

  Future<List<Map<String, dynamic>>?> searchUsers(String query) async {
    try {
      final resp = await _dio.get(
        '/api/users/search',
        queryParameters: {'query': query},
      );
      if (resp.data is List) {
        return (resp.data as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> registerMobileUser({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final resp = await _dio.post(
        '/auth/mobile/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );
      return resp.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<int?> getUserCoins() async {
    try {
      final resp = await _dio.get('/api/user/coins');
      if (resp.data is int) return resp.data as int;
      if (resp.data is Map && resp.data['coins'] != null) {
        return (resp.data['coins'] as num).toInt();
      }
    } catch (_) {}
    return null;
  }

  @Deprecated('Use QuizApiService instead.')
  Future<List<Map<String, dynamic>>?> getQuestions(
    String topicKey,
    int count,
  ) {
    return _quizApi.getQuestions(topicKey, count);
  }

  @Deprecated('Use QuizApiService instead.')
  Future<Map<String, dynamic>?> submitAnswer(
    String quizId,
    int questionId,
    String answer,
    int timeSpentSeconds, [
    String? token,
  ]) {
    return _quizApi.submitAnswer(
      quizId,
      questionId,
      answer,
      timeSpentSeconds,
      token,
    );
  }

  Future<Map<String, dynamic>?> getDailyHintUsage() async {
    try {
      final resp = await _dio.get(
        '/api/hints/daily',
        options: Options(
          validateStatus: (status) =>
              status != null && (status < 400 || status == 404),
        ),
      );
      if (resp.statusCode == 404) {
        return null;
      }
      if (resp.data is Map<String, dynamic>) {
        return resp.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  @Deprecated('Use LeaderboardApiService.fetchLeaderboard instead.')
  Future<LeaderboardResponse?> fetchLeaderboard({
    required String scope,
    required String period,
    int limit = 50,
    String? cursor,
  }) {
    return _leaderboardApi.fetchLeaderboard(
      scope: scope,
      period: period,
      limit: limit,
      cursor: cursor,
    );
  }

  Future<List<dynamic>?> getTopicsProgress() async {
    try {
      final resp = await _dio.get(
        '/api/progress/topics',
        options: Options(
          validateStatus: (status) =>
              status != null && (status < 400 || status == 404),
        ),
      );
      if (resp.statusCode == 404) {
        return null;
      }
      if (resp.data is List) {
        return resp.data as List<dynamic>;
      }
      if (resp.data is Map<String, dynamic> &&
          (resp.data as Map<String, dynamic>)['items'] is List) {
        return (resp.data as Map<String, dynamic>)['items'] as List<dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> fetchFormulaHint(int questionId) async {
    try {
      final resp = await _dio.get(
        '/api/hints/formula',
        queryParameters: {'questionId': questionId},
      );
      if (resp.data is String) return _sanitizeMathString(resp.data as String);
      if (resp.data is Map && resp.data['formula'] != null) {
        return _sanitizeMathString(resp.data['formula'].toString());
      }
    } catch (_) {}
    return null;
  }

  @Deprecated('Use LeaderboardApiService.fetchLeaderboardRivals instead.')
  Future<List<RivalLeaderboardEntry>?> fetchLeaderboardRivals({
    required String period,
  }) {
    return _leaderboardApi.fetchRivals(period: period);
  }

  Future<String?> fetchClueHint(int questionId) async {
    try {
      final resp = await _dio.get(
        '/api/hints/clue',
        queryParameters: {'questionId': questionId},
      );
      if (resp.data is String) return _sanitizeMathString(resp.data as String);
      if (resp.data is Map && resp.data['clue'] != null) {
        return _sanitizeMathString(resp.data['clue'].toString());
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>?> eliminateOption(int questionId) async {
    try {
      final resp = await _dio.post(
        '/api/hints/eliminate',
        data: {'questionId': questionId},
      );
      if (resp.data is List) {
        return (resp.data as List).map((e) => e.toString()).toList();
      }
      if (resp.data is Map && resp.data['remainingOptions'] is List) {
        return (resp.data['remainingOptions'] as List)
            .map((e) => e.toString())
            .toList();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) {
        final retryHeader = e.response?.headers.value('retry-after');
        final retryAfter = retryHeader != null
            ? Duration(seconds: int.tryParse(retryHeader) ?? 0)
            : null;
        throw ApiRateLimitedException(retryAfter);
      }
    }
    return null;
  }

  @Deprecated(
    'Use LeaderboardApiService.fetchSchoolVsSchoolLeaderboard instead.',
  )
  Future<SchoolLeaderboardResponse?> fetchSchoolVsSchoolLeaderboard({
    required String period,
    int limit = 50,
    String? cursor,
  }) {
    return _leaderboardApi.fetchSchoolVsSchoolLeaderboard(
      period: period,
      limit: limit,
      cursor: cursor,
    );
  }

  @Deprecated('Use LeaderboardApiService.fetchSchoolLeaderboard instead.')
  Future<SchoolLeaderboardFeed?> fetchSchoolLeaderboard({
    required String period,
    int limit = 50,
    String? cursor,
  }) {
    return _leaderboardApi.fetchSchoolLeaderboard(
      period: period,
      limit: limit,
      cursor: cursor,
    );
  }

  @Deprecated(
    'Use LeaderboardApiService.fetchSchoolLeaderboardDetail instead.',
  )
  Future<SchoolLeaderboardDetail?> fetchSchoolLeaderboardDetail({
    required int schoolId,
    required String period,
  }) {
    return _leaderboardApi.fetchSchoolLeaderboardDetail(
      schoolId: schoolId,
      period: period,
    );
  }

  @Deprecated(
    'Use LeaderboardApiService.fetchSchoolLeaderboardHistory instead.',
  )
  Future<List<SchoolLeaderboardHistoryPoint>?>
  fetchSchoolLeaderboardHistory({
    required int schoolId,
    required String period,
    int take = 30,
  }) {
    return _leaderboardApi.fetchSchoolLeaderboardHistory(
      schoolId: schoolId,
      period: period,
      take: take,
    );
  }

  @Deprecated('Use AdaptiveContentApiService instead.')
  Future<ApiResult<Map<String, dynamic>>> getAdaptivePathForUserResult(
    String userId,
  ) {
    return _adaptiveContentApiService.getAdaptivePathForUserResult(userId);
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getMasteryForUserResult(
    String userId, {
    int page = 1,
    int pageSize = 5,
  }) {
    // TODO: Backend mastery endpoint is not implemented; using empty fallback
    // until product contract is defined.
    return Future<ApiResult<List<Map<String, dynamic>>>>.value(
      ApiResult(data: const <Map<String, dynamic>>[], statusCode: 200),
    );
  }

  Future<ApiResult<List<Map<String, dynamic>>>> getWeaknessForUserResult(
    String userId, {
    int page = 1,
    int pageSize = 5,
  }) {
    return _requestResult<List<Map<String, dynamic>>>(
      () => _dio.get(
        '/api/analytics/weakness',
        queryParameters: {'page': page, 'pageSize': pageSize},
      ),
      _normalizeListPayload,
    );
  }

  Future<ApiResult<List<Map<String, dynamic>>>>
  getPracticeRecommendationsForUserResult(
    String userId, {
    int page = 1,
    int pageSize = 10,
  }) {
    return _requestResult<List<Map<String, dynamic>>>(
      () => _dio.get(
        '/api/recommendations/practice',
        queryParameters: {'page': page, 'pageSize': pageSize},
      ),
      _normalizeListPayload,
    );
  }

  Future<ApiResult<Map<String, dynamic>>> startPracticeSessionResult(
    Map<String, dynamic> payload,
  ) {
    return _requestResult<Map<String, dynamic>>(
      () => _dio.post('/api/practice/session/start', data: payload),
      (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> submitPracticeSessionAnswerResult(
    String sessionId,
    Map<String, dynamic> payload,
  ) {
    return _requestResult<Map<String, dynamic>>(
      () => _dio.post('/api/practice/session/$sessionId/answer', data: payload),
      (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  Future<ApiResult<Map<String, dynamic>>> completePracticeSessionResult(
    String sessionId,
  ) {
    return _requestResult<Map<String, dynamic>>(
      () => _dio.post('/api/practice/session/$sessionId/complete'),
      (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
  }

  @Deprecated('Use AdaptiveContentApiService instead.')
  Future<Map<String, dynamic>?> getAdaptiveRecommendations() async {
    return _adaptiveContentApiService.getAdaptiveRecommendations();
  }

  @Deprecated('Use AdaptiveContentApiService instead.')
  Future<ApiResult<Map<String, dynamic>>> getAdaptiveRecommendationsResult() {
    return _adaptiveContentApiService.getAdaptiveRecommendationsResult();
  }

  // Legacy adaptive session endpoints have been removed from runtime use.
  // Practice session flow under `/api/practice/session/*` is canonical; callers
  // should use `PracticeSessionApiService` instead.

  @Deprecated('Use AdaptiveContentApiService instead.')
  Future<List<Map<String, dynamic>>?> getAdaptiveReview() async {
    return _adaptiveContentApiService.getAdaptiveReview();
  }

  @Deprecated('Use AdaptiveContentApiService instead.')
  Future<ApiResult<List<Map<String, dynamic>>>> getAdaptiveReviewResult() {
    return _adaptiveContentApiService.getAdaptiveReviewResult();
  }

  @Deprecated('Use AdaptiveContentApiService instead.')
  Future<Map<String, dynamic>?> getAdaptivePath() async {
    return _adaptiveContentApiService.getAdaptivePath();
  }

  @Deprecated('Use AdaptiveContentApiService instead.')
  Future<ApiResult<Map<String, dynamic>>> getAdaptivePathResult() {
    return _adaptiveContentApiService.getAdaptivePathResult();
  }

  // Generic helpers kept only for temporary legacy compatibility.
  // New runtime code should use domain services (ProgressApiService, etc.).
  // Temporary legacy compatibility only. Do not add new callers.
  @Deprecated(
    'Use typed domain API services. Generic endpoint calls are forbidden in new runtime code.',
  )
  Future<Map<String, dynamic>?> get(String endpoint, [String? token]) async {
    try {
      final response = await _dio.get(endpoint);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  // Temporary legacy compatibility only. Do not add new callers.
  @Deprecated(
    'Use typed domain API services. Generic endpoint calls are forbidden in new runtime code.',
  )
  Future<Map<String, dynamic>?> post(
    String endpoint,
    Map data, [
    String? token,
  ]) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  List<Map<String, dynamic>> _normalizeListPayload(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (data is Map<String, dynamic>) {
      final nestedData = data['data'];
      if (nestedData is List) {
        return nestedData.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }

      final nestedItems = data['items'];
      if (nestedItems is List) {
        return nestedItems.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }

      if (nestedData is Map<String, dynamic>) {
        return [nestedData];
      }

      return [data];
    }

    return const <Map<String, dynamic>>[];
  }

  String _sanitizeMathString(String value) {
    final normalized = MathContentParser.normalizeInput(value);
    return normalized.isEmpty ? value.trim() : normalized;
  }
}
