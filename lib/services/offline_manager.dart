import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/question.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'offline_storage_service.dart';
import 'quiz_api_service.dart';
import 'srs_service.dart';

enum AnswerSubmitStatus {
  serverConfirmed,
  queuedOffline,
  failed,
}

class AnswerSubmitResult {
  final AnswerSubmitStatus status;
  final Map<String, dynamic>? serverResponse;

  const AnswerSubmitResult({
    required this.status,
    this.serverResponse,
  });
}

class OfflineManager {
  static OfflineManager? _instance;
  static OfflineManager get instance => _instance ??= OfflineManager._();

  OfflineManager._();

  final QuizApiService _quizApi = QuizApiService();
  final SrsService _srs = SrsService.instance;

  ConnectivityService? _connectivity;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _initialized = false;

  final StreamController<int> _pendingCountController =
      StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  DateTime? _lastSyncAttemptAt;
  DateTime? _lastSyncSuccessAt;
  String? _lastSyncError;

  DateTime? get lastSyncAttemptAt => _lastSyncAttemptAt;
  DateTime? get lastSyncSuccessAt => _lastSyncSuccessAt;
  String? get lastSyncError => _lastSyncError;

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
    final userId = _resolveUserId();
    final answers = await OfflineStorageService.getPendingAnswers(
      userId: userId,
    );
    final srs = await OfflineStorageService.getPendingSrsUpdates(
      userId: userId,
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
    _lastSyncAttemptAt = DateTime.now();
    if (!_isOnlineWithToken) {
      await emitPendingCount();
      return;
    }

    try {
      await _syncPendingAnswers();
      await _syncPendingSrs();
      _lastSyncSuccessAt = DateTime.now();
      _lastSyncError = null;
    } catch (e) {
      _lastSyncError = e.toString();
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
        final raw = await _quizApi.getQuestions('topic_$subtopicId', count);
        if (raw != null && raw.isNotEmpty) {
          await OfflineStorageService.cacheQuestions(subtopicId, raw);
          return raw.map((e) => Question.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint(
          'OfflineManager.getQuizQuestions: online fetch failed, using cache: $e',
        );
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
      } catch (e) {
        debugPrint(
          'OfflineManager.getDailyReviewQuestions: online fetch failed, using cache: $e',
        );
      }
    }

    final userId = _resolveUserId();
    final cached = await OfflineStorageService.getCachedDailySrsQuestions(
      userId: userId,
    );
    return cached.map((e) => Question.fromJson(e)).toList();
  }

  Future<void> _syncPendingAnswers() async {
    final userId = _resolveUserId();
    final pendingAnswers = await OfflineStorageService.getPendingAnswers(
      userId: userId,
    );
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
          final result = await _quizApi.submitAnswer(
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
    await OfflineStorageService.clearPendingAnswers(userId: userId);
    for (final answer in failed) {
      await OfflineStorageService.savePendingAnswer(
        quizId: answer['quiz_id'].toString(),
        questionId: (answer['question_id'] as num).toInt(),
        answer: answer['answer'].toString(),
        timeSpentSeconds: (answer['time_spent_seconds'] as num).toInt(),
        isCorrect: (answer['is_correct'] as num?)?.toInt() == 1,
        userId: answer['user_id']?.toString() ?? userId,
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
    if (_isOnlineWithToken) {
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
      } catch (e) {
        debugPrint(
          'OfflineManager.submitSrsUpdate: online submit failed, queueing: $e',
        );
      }
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
        final questions = await _quizApi.getQuestions(
          'topic_$subtopicId',
          count,
        );
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
      final questions = await _quizApi.getQuestions('topic_$subtopicId', count);
      if (questions != null) {
        await OfflineStorageService.cacheQuestions(subtopicId, questions);
      }
    } catch (e) {
      debugPrint('preloadQuestions error: $e');
    }
  }

  Future<AnswerSubmitResult> submitAnswer({
    required String quizId,
    required int questionId,
    required String answer,
    required int timeSpentSeconds,
    required bool isCorrect,
    String? token,
  }) async {
    if (_isOnlineWithToken) {
      try {
        final result = await _quizApi.submitAnswer(
          quizId,
          questionId,
          answer,
          timeSpentSeconds,
          token,
        );
        if (result != null) {
          try {
            await emitPendingCount();
          } catch (e) {
            debugPrint(
              'OfflineManager.submitAnswer: failed to emit pending count after server submit: $e',
            );
          }
          return AnswerSubmitResult(
            status: AnswerSubmitStatus.serverConfirmed,
            serverResponse: result,
          );
        }
      } on ApiRateLimitedException catch (e) {
        debugPrint(
          'OfflineManager.submitAnswer: rate limited (429). Queueing answer for later (retryAfter=${e.retryAfter}).',
        );
        // Preserve the answer offline, but allow caller to show UI feedback.
        try {
          await OfflineStorageService.savePendingAnswer(
            quizId: quizId,
            questionId: questionId,
            answer: answer,
            timeSpentSeconds: timeSpentSeconds,
            isCorrect: isCorrect,
            userId: _resolveUserId(),
          );
          try {
            await emitPendingCount();
          } catch (e) {
            debugPrint(
              'OfflineManager.submitAnswer: failed to emit pending count after queueing rate-limited answer: $e',
            );
          }
          return const AnswerSubmitResult(
            status: AnswerSubmitStatus.queuedOffline,
          );
        } catch (saveError) {
          debugPrint('OfflineManager.submitAnswer: failed to queue answer: $saveError');
          try {
            await emitPendingCount();
          } catch (e) {
            debugPrint(
              'OfflineManager.submitAnswer: failed to emit pending count after queue failure: $e',
            );
          }
          return const AnswerSubmitResult(status: AnswerSubmitStatus.failed);
        }
      } catch (e) {
        debugPrint(
          'OfflineManager.submitAnswer: online submit failed, queueing: $e',
        );
      }
    }

    try {
      await OfflineStorageService.savePendingAnswer(
        quizId: quizId,
        questionId: questionId,
        answer: answer,
        timeSpentSeconds: timeSpentSeconds,
        isCorrect: isCorrect,
        userId: _resolveUserId(),
      );
      try {
        await emitPendingCount();
      } catch (e) {
        debugPrint(
          'OfflineManager.submitAnswer: failed to emit pending count after queueing answer: $e',
        );
      }
      return const AnswerSubmitResult(
        status: AnswerSubmitStatus.queuedOffline,
      );
    } catch (e) {
      debugPrint('OfflineManager.submitAnswer: failed to queue answer: $e');
      try {
        await emitPendingCount();
      } catch (emitError) {
        debugPrint(
          'OfflineManager.submitAnswer: failed to emit pending count after queue error: $emitError',
        );
      }
      return const AnswerSubmitResult(status: AnswerSubmitStatus.failed);
    }
  }

  Future<int> getPendingAnswersCount() async {
    final pending = await OfflineStorageService.getPendingAnswers(
      userId: _resolveUserId(),
    );
    return pending.length;
  }

  Future<int> getPendingSrsUpdatesCount() async {
    return OfflineStorageService.getPendingSrsUpdatesCount(
      userId: _resolveUserId(),
    );
  }
}

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

