import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'offline_storage_service.dart';
import 'api_service.dart';

class OfflineManager {
  static OfflineManager? _instance;
  static OfflineManager get instance => _instance ??= OfflineManager._();
  
  OfflineManager._();

  final ApiService _api = ApiService();
  late ConnectivityService _connectivity;
  
  void initialize() {
    _connectivity = ConnectivityService.instance;
    _connectivity.initialize();
    
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncPendingData();
      }
    });
  }

  /// Sync all pending offline data when connection is restored
  Future<void> syncPendingData() async {
    try {
      debugPrint('🔄 Starting offline data sync...');
      
      await syncPendingAnswers();
      
      debugPrint('✅ Offline data sync completed');
    } catch (e) {
      debugPrint('❌ Error syncing offline data: $e');
    }
  }

  /// Submit all pending quiz answers via batch API
  Future<void> syncPendingAnswers({String? token}) async {
    final pendingAnswers = await OfflineStorageService.getPendingAnswers();
    
    if (pendingAnswers.isEmpty) {
      debugPrint('No pending answers to sync');
      return;
    }

    debugPrint('Syncing ${pendingAnswers.length} pending answers...');

    // Convert to API format
    final apiAnswers = pendingAnswers.map((answer) => {
      'quizId': answer['quiz_id'],
      'questionId': answer['question_id'],
      'answer': answer['answer'],
      'timeSpentSeconds': answer['time_spent_seconds'],
      'timestamp': answer['timestamp'],
      'isCorrect': answer['is_correct'] == 1,
    }).toList();

    try {
      final result = await _api.batchSubmitAnswers(apiAnswers, token);
      
      if (result != null) {
        // Clear pending answers on successful sync
        await OfflineStorageService.clearPendingAnswers();
        debugPrint('✅ Successfully synced ${pendingAnswers.length} answers');
      } else {
        debugPrint('❌ Failed to sync pending answers');
      }
    } catch (e) {
      debugPrint('❌ Error syncing pending answers: $e');
    }
  }

  /// Cache questions for offline use
  Future<void> preloadQuestions(int subtopicId, int count, String? token) async {
    if (!_connectivity.isOnline) {
      debugPrint('Cannot preload questions - offline mode');
      return;
    }

    try {
      final questions = await _api.getQuestions('topic_$subtopicId', count);
      if (questions != null) {
        await OfflineStorageService.cacheQuestions(subtopicId, questions);
        debugPrint('✅ Cached ${questions.length} questions for subtopic $subtopicId');
      }
    } catch (e) {
      debugPrint('❌ Error preloading questions: $e');
    }
  }

  /// Get questions (online first, fallback to cache)
  Future<List<Map<String, dynamic>>?> getQuestions(int subtopicId, int count, String? token) async {
    if (_connectivity.isOnline) {
      // Try online first
      try {
        final questions = await _api.getQuestions('topic_$subtopicId', count);
        if (questions != null) {
          // Cache for offline use
          await OfflineStorageService.cacheQuestions(subtopicId, questions);
          return questions;
        }
      } catch (e) {
        debugPrint('Online questions failed, falling back to cache: $e');
      }
    }

    // Fallback to cached questions
    debugPrint('Using cached questions for subtopic $subtopicId');
    return await OfflineStorageService.getCachedQuestions(subtopicId, count);
  }

  /// Submit answer (online or queue for offline)
  Future<bool> submitAnswer({
    required String quizId,
    required int questionId,
    required String answer,
    required int timeSpentSeconds,
    required bool isCorrect,
    String? token,
  }) async {
    if (_connectivity.isOnline) {
      // Try online submit
      try {
        final result = await _api.submitAnswer(quizId, questionId, answer, timeSpentSeconds, token);
        return result != null;
      } catch (e) {
        debugPrint('Online submit failed, saving for offline sync: $e');
      }
    }

    // Save for offline sync
    await OfflineStorageService.savePendingAnswer(
      quizId: quizId,
      questionId: questionId,
      answer: answer,
      timeSpentSeconds: timeSpentSeconds,
      isCorrect: isCorrect,
    );
    
    debugPrint('📱 Answer saved for offline sync');
    return true;
  }

  /// Check if device is online
  bool get isOnline => _connectivity.isOnline;

  /// Get pending answers count
  Future<int> getPendingAnswersCount() async {
    final pending = await OfflineStorageService.getPendingAnswers();
    return pending.length;
  }
}