import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/progress_overview.dart';
import 'auth_service.dart';

class ApiService {
  /// Fetches topic progress for the user
  Future<List<Map<String, dynamic>>?> getTopicsProgress() async {
    try {
      final response = await _dio.get('/api/progress/topics');
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching topics progress: $e');
      return null;
    }
  }

  late Dio _dio;

  ApiService() {
    _dio = AuthService.instance.client;
  }

  Future<Map<String, dynamic>?> post(
    String endpoint,
    Map data,
    String? token,
  ) async {
    try {
      final response = await _dio.post(endpoint, data: data);

      debugPrint("POST $endpoint - Status: ${response.statusCode}");

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data is Map<String, dynamic> ? response.data : null;
      }

      debugPrint("API ERROR: ${response.statusCode} => ${response.data}");
      return null;
    } catch (e) {
      debugPrint("Network error on $endpoint: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> get(String endpoint, String? token) async {
    try {
      final response = await _dio.get(endpoint);

      debugPrint(
        "GET $endpoint - Status: ${response.statusCode}, Token: ${token != null ? 'Present' : 'None'}",
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data is Map<String, dynamic> ? response.data : null;
      }

      debugPrint("API ERROR: ${response.statusCode} => ${response.data}");
      return null;
    } catch (e) {
      debugPrint("Network error on $endpoint: $e");
      return null;
    }
  }

  // Quiz API methods
  Future<Map<String, dynamic>?> startQuiz(
    int subtopicId,
    int questionCount,
    String? token,
  ) async {
    try {
      return await post('/api/quiz/start', {
        'subtopicId': subtopicId,
        'questionCount': questionCount,
      }, token);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getNextQuestion(
    String quizId,
    int subtopicId,
    String? token,
  ) async {
    try {
      return await post('/api/quiz/next-question', {
        'quizId': quizId,
        'subtopicId': subtopicId,
      }, token);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitAnswer(
    String quizId,
    int questionId,
    String answer,
    int timeSpentSeconds,
    String? token,
  ) async {
    try {
      return await post('/api/quiz/answer', {
        'quizId': quizId,
        'questionId': questionId,
        'answer': answer,
        'timeSpentSeconds': timeSpentSeconds,
      }, token);
    } catch (e) {
      return null;
    }
  }

  // NEW: Batch submit for offline mode
  Future<Map<String, dynamic>?> batchSubmitAnswers(
    List<Map<String, dynamic>> answers,
    String? token,
  ) async {
    try {
      return await post('/api/quiz/batch-submit', {'answers': answers}, token);
    } catch (e) {
      return null;
    }
  }

  // HINT SYSTEM METHODS
  Future<String?> fetchFormulaHint(int questionId) async {
    try {
      final response = await _dio.get(
        "/api/questions/$questionId/hint/formula",
      );
      return response.data["formula"];
    } catch (e) {
      debugPrint('Error fetching formula hint: $e');
      return null;
    }
  }

  Future<String?> fetchClueHint(int questionId) async {
    try {
      final response = await _dio.get("/api/questions/$questionId/hint/clue");
      return response.data["clue"];
    } catch (e) {
      debugPrint('Error fetching clue hint: $e');
      return null;
    }
  }

  Future<List<String>?> eliminateOption(int questionId) async {
    try {
      final response = await _dio.post(
        "/api/questions/$questionId/hint/eliminate",
      );
      return List<String>.from(response.data["remainingOptions"]);
    } catch (e) {
      debugPrint('Error eliminating option: $e');
      return null;
    }
  }

  // Get user coins
  Future<int?> getUserCoins() async {
    try {
      final response = await _dio.get("/api/user/coins");
      return response.data["coins"];
    } catch (e) {
      debugPrint('Error fetching coins: $e');
      return null;
    }
  }

  // Get daily hint usage
  Future<Map<String, dynamic>?> getDailyHintUsage() async {
    try {
      final response = await _dio.get("/api/user/daily-hints");
      return response.data;
    } catch (e) {
      debugPrint('Error fetching daily hints: $e');
      return null;
    }
  }

  // Leaderboard API methods
  Future<List<Map<String, dynamic>>?> getGlobalLeaderboard(
    String range,
    int limit,
    String? token,
  ) async {
    try {
      final response = await _dio.get(
        '/api/leaderboard/global?range=$range&limit=$limit',
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getFriendsLeaderboard(
    String range,
    int limit,
    String? token,
  ) async {
    try {
      final response = await _dio.get(
        '/api/leaderboard/friends?range=$range&limit=$limit',
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current user's rank (even if not in top N)
  Future<Map<String, dynamic>?> getUserRank(String range, String? token) async {
    try {
      final response = await _dio.get('/api/leaderboard/me?range=$range');

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data is Map<String, dynamic> ? response.data : null;
      }
      return null;
    } catch (e) {
      debugPrint('getUserRank failed: $e');
      return null;
    }
  }

  // Progress API methods
  Future<List<Map<String, dynamic>>?> getProgressWeakAreas(
    String? token,
  ) async {
    try {
      final response = await _dio.get('/api/progress/weak-areas');
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300 &&
          response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<ProgressOverview> getProgressOverview() async {
    ProgressOverview fallback() => ProgressOverview(
      totalQuizzes: 0,
      completedQuizzes: 0,
      averageScore: 0.0,
      bestScore: 0.0,
      lastQuizDate: DateTime.now(),
    );

    try {
      final response = await _dio.get('/api/progress/overview');
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        // Current backend shape:
        // { totalAttempts, accuracy, streak }
        if (data.containsKey('totalAttempts') || data.containsKey('accuracy')) {
          final attempts = (data['totalAttempts'] as num?)?.toInt() ?? 0;
          final accuracyPercent = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
          final ratio = (accuracyPercent / 100.0).clamp(0.0, 1.0).toDouble();

          return ProgressOverview(
            totalQuizzes: attempts,
            completedQuizzes: attempts,
            averageScore: ratio,
            bestScore: ratio,
            lastQuizDate: DateTime.now(),
          );
        }

        // Legacy shape expected by ProgressOverview model.
        return ProgressOverview.fromJson(data);
      }

      return fallback();
    } catch (e) {
      return fallback();
    }
  }

  // Add missing getQuestions method for fallback
  Future<List<Map<String, dynamic>>?> getQuestions(
    String topic,
    int count,
  ) async {
    try {
      final response = await _dio.post(
        '/api/quiz/questions',
        data: {'topic': topic, 'count': count},
      );
      if (response.data != null && response.data['questions'] != null) {
        return List<Map<String, dynamic>>.from(response.data['questions']);
      }
    } catch (e) {
      debugPrint('getQuestions failed: $e');
    }
    return null;
  }

  Future<bool> authenticate(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      return response.data != null && response.data['token'] != null;
    } catch (e) {
      debugPrint("Auth failed: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> register(
    String username,
    String password,
    String email,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'username': username, 'password': password, 'email': email},
      );
      return response.data;
    } catch (e) {
      debugPrint("Register failed: $e");
      return null;
    }
  }

  // NEW MOBILE USER ENDPOINTS

  /// Register new mobile user with all required fields
  Future<Map<String, dynamic>?> registerMobileUser({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/mobile/register',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'displayName': displayName,
        },
      );

      debugPrint("Mobile registration - Status: ${response.statusCode}");

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data;
      }

      debugPrint(
        "Mobile registration error: ${response.statusCode} => ${response.data}",
      );
      return null;
    } catch (e) {
      debugPrint("Mobile registration failed: $e");
      return null;
    }
  }

  /// Get user profile information
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _dio.get('/api/users/profile');

      debugPrint("Get profile - Status: ${response.statusCode}");

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data;
      }

      debugPrint(
        "Get profile error: ${response.statusCode} => ${response.data}",
      );
      return null;
    } catch (e) {
      debugPrint("Get profile failed: $e");
      return null;
    }
  }

  /// Update user profile (display name)
  Future<Map<String, dynamic>?> updateUserProfile({
    String? displayName,
    String? email,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (displayName != null) data['displayName'] = displayName;
      if (email != null) data['email'] = email;

      final response = await _dio.put('/api/users/profile', data: data);

      debugPrint("Update profile - Status: ${response.statusCode}");

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return response.data;
      }

      debugPrint(
        "Update profile error: ${response.statusCode} => ${response.data}",
      );
      return null;
    } catch (e) {
      debugPrint("Update profile failed: $e");
      return null;
    }
  }

  /// Search users by query string
  Future<List<Map<String, dynamic>>?> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/api/users/search',
        queryParameters: {'query': query},
      );

      debugPrint(
        "Search users - Status: ${response.statusCode}, Query: $query",
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      debugPrint(
        "Search users error: ${response.statusCode} => ${response.data}",
      );
      return null;
    } catch (e) {
      debugPrint("Search users failed: $e");
      return null;
    }
  }
}
