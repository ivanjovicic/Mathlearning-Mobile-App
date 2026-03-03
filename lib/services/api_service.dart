import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/progress_overview.dart';
import '../models/leaderboard_models.dart';
import '../models/school_leaderboard_models.dart';

// Models
class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final int? statusCode;
  final bool isRateLimited;
  final Duration? retryAfter;

  ApiResult({
    this.data,
    this.error,
    this.statusCode,
    this.isRateLimited = false,
    this.retryAfter,
  });

  bool get isSuccess => data != null && error == null;
}

class ApiError {
  final String message;
  final StackTrace? stackTrace;
  final DioExceptionType? dioErrorType;
  final int? statusCode;
  final Duration? retryAfter;
  final dynamic responseBody;

  ApiError({
    required this.message,
    this.stackTrace,
    this.dioErrorType,
    this.statusCode,
    this.retryAfter,
    this.responseBody,
  });
}

// Utility for error parsing
ApiError parseError(DioException e) {
  final retryAfter = e.response?.headers.value('retry-after');
  return ApiError(
    message: e.message ?? e.toString(),
    stackTrace: e.stackTrace,
    dioErrorType: e.type,
    statusCode: e.response?.statusCode,
    retryAfter: retryAfter != null ? Duration(seconds: int.tryParse(retryAfter) ?? 0) : null,
    responseBody: e.response?.data,
  );
}

// Root API Client
class ApiClient {
  final Dio _dio;
  final AuthApi auth;
  final QuizApi quiz;
  final UserApi user;
  final ProgressApi progress;

  ApiClient(Dio dio)
      : _dio = dio,
        auth = AuthApi(dio),
        quiz = QuizApi(dio),
        user = UserApi(dio),
        progress = ProgressApi(dio);
}

// Auth API
class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<ApiResult<bool>> authenticate(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      return ApiResult(data: response.data['token'] != null);
    } on DioException catch (e) {
      return ApiResult(error: parseError(e));
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
      return ApiResult(error: parseError(e));
    }
  }
}


// Quiz API
class QuizApi {
  final Dio _dio;

  QuizApi(this._dio);

  Future<ApiResult<Map<String, dynamic>>> startQuiz(
    int subtopicId,
    int questionCount,
  ) async {
    try {
      final response = await _dio.post(
        '/api/quiz/start',
        data: {'subtopicId': subtopicId, 'questionCount': questionCount},
      );
      return ApiResult(data: response.data);
    } on DioException catch (e) {
      return ApiResult(error: parseError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> submitAnswer(
    String quizId,
    int questionId,
    String answer,
    int timeSpentSeconds,
  ) async {
    try {
      final response = await _dio.post(
        '/api/quiz/answer',
        data: {
          'quizId': quizId,
          'questionId': questionId,
          'answer': answer,
          'timeSpentSeconds': timeSpentSeconds,
        },
      );
      return ApiResult(data: response.data);
    } on DioException catch (e) {
      return ApiResult(error: parseError(e));
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
      return ApiResult(error: parseError(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> updateUserProfile({
    String? displayName,
    String? email,
  }) async {
    try {
      final response = await _dio.put(
        '/api/users/profile',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (email != null) 'email': email,
        },
      );
      return ApiResult(data: response.data);
    } on DioException catch (e) {
      return ApiResult(error: parseError(e));
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
      return ApiResult(error: parseError(e));
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

// Exception used by legacy callers when server responds with 429.
class ApiRateLimitedException implements Exception {
  final Duration? retryAfter;
  ApiRateLimitedException([this.retryAfter]);

  @override
  String toString() => 'ApiRateLimitedException(retryAfter: $retryAfter)';
}

// Legacy compatibility: provide `ApiService` class expected by older callers.
class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._() {
    _dio = Dio();
    _client = ApiClient(_dio);
  }

  late Dio _dio;
  late ApiClient _client;

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

  Future<Map<String, dynamic>?> updateUserProfile({String? displayName, String? email}) async {
    final res = await _client.user.updateUserProfile(displayName: displayName, email: email);
    return res.data;
  }

  Future<List<Map<String, dynamic>>?> searchUsers(String query) async {
    try {
      final resp = await _dio.get('/api/users/search', queryParameters: {'q': query});
      if (resp.data is List) return (resp.data as List).cast<Map<String, dynamic>>();
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
      final resp = await _dio.post('/api/users/register-mobile', data: {
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      });
      return resp.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<int?> getUserCoins() async {
    try {
      final resp = await _dio.get('/api/users/coins');
      if (resp.data is int) return resp.data as int;
      if (resp.data is Map && resp.data['coins'] != null) return (resp.data['coins'] as num).toInt();
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>?> getQuestions(String topicKey, int count) async {
    try {
      final resp = await _dio.get('/api/quiz/questions', queryParameters: {'topic': topicKey, 'count': count});
      if (resp.data is List) return (resp.data as List).cast<Map<String, dynamic>>();
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> submitAnswer(String quizId, int questionId, String answer, int timeSpentSeconds, [String? token]) async {
    try {
      final resp = await _dio.post('/api/quiz/answer', data: {
        'quizId': quizId,
        'questionId': questionId,
        'answer': answer,
        'timeSpentSeconds': timeSpentSeconds,
      });
      return resp.data as Map<String, dynamic>?;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) {
        final retryHeader = e.response?.headers.value('retry-after');
        final retryAfter = retryHeader != null ? Duration(seconds: int.tryParse(retryHeader) ?? 0) : null;
        throw ApiRateLimitedException(retryAfter);
      }
      return null;
    }
  }

  // Legacy: daily hint usage
  Future<Map<String, dynamic>?> getDailyHintUsage() async {
    try {
      final resp = await _dio.get('/api/hints/daily');
      if (resp.data is Map) return resp.data as Map<String, dynamic>?;
    } catch (_) {}
    return null;
  }

  Future<LeaderboardResponse?> fetchLeaderboard({
    required String scope,
    required String period,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final resp = await _dio.get('/api/leaderboard', queryParameters: {
        'scope': scope,
        'period': period,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      });
      if (resp.data is Map) return LeaderboardResponse.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>?> getTopicsProgress() async {
    try {
      final resp = await _dio.get('/api/topics/progress');
      if (resp.data is List) return resp.data as List<dynamic>;
    } catch (_) {}
    return null;
  }

  Future<String?> fetchFormulaHint(int questionId) async {
    try {
      final resp = await _dio.get('/api/hints/formula', queryParameters: {'questionId': questionId});
      if (resp.data is String) return resp.data as String;
      if (resp.data is Map && resp.data['formula'] != null) return resp.data['formula'].toString();
    } catch (_) {}
    return null;
  }

  Future<String?> fetchClueHint(int questionId) async {
    try {
      final resp = await _dio.get('/api/hints/clue', queryParameters: {'questionId': questionId});
      if (resp.data is String) return resp.data as String;
      if (resp.data is Map && resp.data['clue'] != null) return resp.data['clue'].toString();
    } catch (_) {}
    return null;
  }

  Future<List<String>?> eliminateOption(int questionId) async {
    try {
      final resp = await _dio.post('/api/hints/eliminate', data: {'questionId': questionId});
      if (resp.data is List) return (resp.data as List).map((e) => e.toString()).toList();
      if (resp.data is Map && resp.data['remainingOptions'] is List) {
        return (resp.data['remainingOptions'] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) {
        final retryHeader = e.response?.headers.value('retry-after');
        final retryAfter = retryHeader != null ? Duration(seconds: int.tryParse(retryHeader) ?? 0) : null;
        throw ApiRateLimitedException(retryAfter);
      }
    }
    return null;
  }

  Future<SchoolLeaderboardResponse?> fetchSchoolVsSchoolLeaderboard({
    required String period,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final resp = await _dio.get('/api/leaderboard/schools', queryParameters: {
        'period': period,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      });
      if (resp.data is Map) return SchoolLeaderboardResponse.fromJson(resp.data as Map<String, dynamic>);
    } catch (_) {}
    return null;
  }

  // Generic helpers
  Future<Map<String, dynamic>?> get(String endpoint, [String? token]) async {
    try {
      final response = await _dio.get(endpoint);
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> post(String endpoint, Map data, [String? token]) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }
}
