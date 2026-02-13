import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/question.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'offline_storage_service.dart';
import 'srs_service.dart';

class OfflineManager {
  static OfflineManager? _instance;
  static OfflineManager get instance => _instance ??= OfflineManager._();

  OfflineManager._();

  final ApiService _api = ApiService();
  final SrsService _srs = SrsService.instance;

  ConnectivityService? _connectivity;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _initialized = false;

  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  String _resolveUserId() => AuthService.instance.userId ?? 'default';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _connectivity = ConnectivityService.instance;
    await _connectivity?.initialize();

    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        _connectivity?.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        syncPendingData();
      } else {
        emitPendingCount();
      }
    });

    await emitPendingCount();

    // Auto-sync on start if user is already logged in
    if (AuthService.instance.isLoggedIn) {
      unawaited(syncPendingData());
    }
  }

  bool get isOnline => _connectivity?.isOnline ?? true;

  bool get _isOnlineWithToken =>
      isOnline &&
      AuthService.instance.isLoggedIn &&
      AuthService.instance.accessToken != null;

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _pendingCountController.close();
  }

  Future<void> emitPendingCount() async {
    if (_pendingCountController.isClosed) return;
    final answers = await OfflineStorageService.getPendingAnswers();
    final srs = await OfflineStorageService.getPendingSrsUpdates(
      userId: _resolveUserId(),
    );
    _pendingCountController.add(answers.length + srs.length);
  }

  /// Manual sync button in UI
  Future<void> manualSync() async {
    await syncPendingData();
  }

  Future<void> retryWithBackoff(
    Future<void> Function() action, {
    int maxAttempts = 4,
  }) async {
    var delay = const Duration(milliseconds: 400);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await action();
        return;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  Future<void> syncPendingData() async {
    if (!_isOnlineWithToken) {
      await emitPendingCount();
      return;
    }

    try {
      await _syncPendingAnswers();
      await _syncPendingSrs();
    } catch (e) {
      debugPrint('Offline sync error: $e');
    } finally {
      await emitPendingCount();
    }
  }

  // ───────── HIGH-LEVEL QUESTION API ─────────

  /// Get quiz questions with online→cache fallback.
  /// Returns parsed [Question] objects ready for QuizProvider.
  Future<List<Question>> getQuizQuestions({
    int subtopicId = 1,
    int count = 10,
  }) async {
    if (_isOnlineWithToken) {
      try {
        final raw = await _api.getQuestions('topic_$subtopicId', count);
        if (raw != null && raw.isNotEmpty) {
          await OfflineStorageService.cacheQuestions(subtopicId, raw);
          return raw.map((e) => Question.fromJson(e)).toList();
        }
      } catch (_) {
        // fallback to cache
      }
    }

    final cached =
        await OfflineStorageService.getCachedQuestions(subtopicId, count);
    if (cached != null) {
      return cached.map((e) => Question.fromJson(e)).toList();
    }
    return [];
  }

  /// Get daily SRS review questions with online→cache fallback.
  Future<List<Question>> getDailyReviewQuestions() async {
    if (_isOnlineWithToken) {
      try {
        final raw = await _srs.fetchDailySrsQuestions();
        if (raw.isNotEmpty) {
          final userId = _resolveUserId();
          await OfflineStorageService.cacheDailySrsQuestions(
            userId: userId,
            questions: raw,
          );
          return raw.map((e) => Question.fromJson(e)).toList();
        }
      } catch (_) {
        // fallback to cache
      }
    }

    final userId = _resolveUserId();
    final cached = await OfflineStorageService.getCachedDailySrsQuestions(
      userId: userId,
    );
    return cached.map((e) => Question.fromJson(e)).toList();
  }

  Future<void> _syncPendingAnswers() async {
    final pendingAnswers = await OfflineStorageService.getPendingAnswers();
    if (pendingAnswers.isEmpty) return;

    final failed = <Map<String, dynamic>>[];

    for (var idx = 0; idx < pendingAnswers.length; idx++) {
      final answer = pendingAnswers[idx];
      final quizId = answer['quiz_id']?.toString();
      final questionId = (answer['question_id'] as num?)?.toInt();
      final value = answer['answer']?.toString();
      final timeSpentSeconds =
          (answer['time_spent_seconds'] as num?)?.toInt() ?? 0;

      if (quizId == null || questionId == null || value == null) {
        continue; // skip malformed entries
      }

      try {
        await retryWithBackoff(() async {
          final result = await _api.submitAnswer(
            quizId,
            questionId,
            value,
            timeSpentSeconds,
            null,
          );
          if (result == null) {
            throw Exception('submitAnswer returned null');
          }
        });
      } on ApiRateLimitedException catch (e) {
        debugPrint(
          'OfflineManager: rate limited (429). Pausing sync for ${e.retryAfter}.',
        );
        // Keep current + remaining items in queue; don't hammer the server.
        failed.add(answer);
        for (var j = idx + 1; j < pendingAnswers.length; j++) {
          failed.add(pendingAnswers[j]);
        }
        break;
      } catch (_) {
        // Even after backoff retries failed -> keep in queue
        failed.add(answer);
      }
    }

    // Replace full queue with only the failed items
    await OfflineStorageService.clearPendingAnswers();
    for (final answer in failed) {
      await OfflineStorageService.savePendingAnswer(
        quizId: answer['quiz_id'].toString(),
        questionId: (answer['question_id'] as num).toInt(),
        answer: answer['answer'].toString(),
        timeSpentSeconds: (answer['time_spent_seconds'] as num).toInt(),
        isCorrect: (answer['is_correct'] as num?)?.toInt() == 1,
      );
    }

    if (failed.isNotEmpty) {
      debugPrint(
        'OfflineManager: ${pendingAnswers.length - failed.length}/${pendingAnswers.length} answers synced, ${failed.length} still pending',
      );
    }
  }

  Future<void> _syncPendingSrs() async {
    final userId = _resolveUserId();
    final pending = await OfflineStorageService.getPendingSrsUpdates(
      userId: userId,
    );
    if (pending.isEmpty) return;

    final failed = <Map<String, dynamic>>[];

    for (final item in pending) {
      final questionId = (item['questionId'] as num?)?.toInt();
      final isCorrect = item['isCorrect'] == true;
      final timeMs = (item['timeMs'] as num?)?.toInt() ?? 0;

      if (questionId == null) continue;

      try {
        await retryWithBackoff(() async {
          final ok = await _srs.updateSrs(
            questionId: questionId,
            isCorrect: isCorrect,
            timeMs: timeMs,
          );
          if (!ok) throw Exception('updateSrs returned false');
        });
      } catch (_) {
        failed.add(item);
      }
    }

    await OfflineStorageService.replacePendingSrsUpdates(
      userId: userId,
      updates: failed,
    );

    if (failed.isNotEmpty) {
      debugPrint(
        'OfflineManager: ${pending.length - failed.length}/${pending.length} SRS updates synced, ${failed.length} still pending',
      );
    }
  }

  Future<void> submitSrsUpdate({
    required int questionId,
    required bool isCorrect,
    required int timeMs,
  }) async {
    if (isOnline) {
      try {
        final ok = await _srs.updateSrs(
          questionId: questionId,
          isCorrect: isCorrect,
          timeMs: timeMs,
        );
        if (ok) {
          await emitPendingCount();
          return;
        }
      } catch (_) {}
    }

    await OfflineStorageService.savePendingSrsUpdate(
      userId: _resolveUserId(),
      questionId: questionId,
      isCorrect: isCorrect,
      timeMs: timeMs,
    );
    await emitPendingCount();
  }

  Future<List<Map<String, dynamic>>?> getQuestions(
    int subtopicId,
    int count,
    String? token,
  ) async {
    if (_isOnlineWithToken) {
      try {
        final questions = await _api.getQuestions('topic_$subtopicId', count);
        if (questions != null) {
          await OfflineStorageService.cacheQuestions(subtopicId, questions);
          return questions;
        }
      } catch (e) {
        debugPrint('Online questions failed, fallback to cache: $e');
      }
    }

    return OfflineStorageService.getCachedQuestions(subtopicId, count);
  }

  Future<void> preloadQuestions(int subtopicId, int count, String? token) async {
    if (!_isOnlineWithToken) {
      return;
    }
    try {
      final questions = await _api.getQuestions('topic_$subtopicId', count);
      if (questions != null) {
        await OfflineStorageService.cacheQuestions(subtopicId, questions);
      }
    } catch (e) {
      debugPrint('preloadQuestions error: $e');
    }
  }

  Future<Map<String, dynamic>?> submitAnswer({
    required String quizId,
    required int questionId,
    required String answer,
    required int timeSpentSeconds,
    required bool isCorrect,
    String? token,
  }) async {
    if (isOnline) {
      try {
        final result = await _api.submitAnswer(
          quizId,
          questionId,
          answer,
          timeSpentSeconds,
          token,
        );
        if (result != null) {
          await emitPendingCount();
          return result;
        }
      } on ApiRateLimitedException catch (e) {
        debugPrint(
          'OfflineManager.submitAnswer: rate limited (429). Queueing answer for later (retryAfter=${e.retryAfter}).',
        );
        // Preserve the answer offline, but allow caller to show UI feedback.
        await OfflineStorageService.savePendingAnswer(
          quizId: quizId,
          questionId: questionId,
          answer: answer,
          timeSpentSeconds: timeSpentSeconds,
          isCorrect: isCorrect,
        );
        await emitPendingCount();
        rethrow;
      } catch (_) {}
    }

    await OfflineStorageService.savePendingAnswer(
      quizId: quizId,
      questionId: questionId,
      answer: answer,
      timeSpentSeconds: timeSpentSeconds,
      isCorrect: isCorrect,
    );
    await emitPendingCount();
    return null;
  }

  Future<int> getPendingAnswersCount() async {
    final pending = await OfflineStorageService.getPendingAnswers();
    return pending.length;
  }

  Future<int> getPendingSrsUpdatesCount() async {
    return OfflineStorageService.getPendingSrsUpdatesCount(
      userId: _resolveUserId(),
    );
  }
}

// ───────── HELPER DATA CLASSES ─────────

class PendingAnswer {
  final String questionId;
  final bool isCorrect;
  final int timeMs;
  final DateTime createdAt;

  PendingAnswer({
    required this.questionId,
    required this.isCorrect,
    required this.timeMs,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'isCorrect': isCorrect,
        'timeMs': timeMs,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingAnswer.fromJson(Map<String, dynamic> json) {
    return PendingAnswer(
      questionId: json['questionId'] as String,
      isCorrect: json['isCorrect'] as bool,
      timeMs: json['timeMs'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PendingSrsUpdate {
  final String questionId;
  final bool isCorrect;
  final int timeMs;
  final DateTime createdAt;

  PendingSrsUpdate({
    required this.questionId,
    required this.isCorrect,
    required this.timeMs,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'isCorrect': isCorrect,
        'timeMs': timeMs,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingSrsUpdate.fromJson(Map<String, dynamic> json) {
    return PendingSrsUpdate(
      questionId: json['questionId'] as String,
      isCorrect: json['isCorrect'] as bool,
      timeMs: json['timeMs'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
