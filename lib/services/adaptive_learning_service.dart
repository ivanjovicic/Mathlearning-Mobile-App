import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'connectivity_service.dart';
import 'srs_service.dart';
import '../models/path_node.dart';
import 'network/retry_executor.dart';

/// Models for Adaptive Learning
class AdaptivePracticeData {
  final int? topicId;
  final String topic;
  final String difficulty;
  final int questionCount;
  final String confidence;

  AdaptivePracticeData({
    this.topicId,
    required this.topic,
    required this.difficulty,
    required this.questionCount,
    required this.confidence,
  });
}

class AdaptiveSession {
  final String sessionId;
  final List<int> questionIds;
  final String topic;
  final String difficulty;

  AdaptiveSession({
    required this.sessionId,
    required this.questionIds,
    required this.topic,
    required this.difficulty,
  });
}

class AdaptiveRecommendation {
  final int? topicId;
  final String topic;
  final String difficulty;
  final int questionCount;
  final String reasoning;

  AdaptiveRecommendation({
    this.topicId,
    required this.topic,
    required this.difficulty,
    required this.questionCount,
    required this.reasoning,
  });
}

class TopicMastery {
  final String topic;
  final double masteryScore;

  TopicMastery({
    required this.topic,
    required this.masteryScore,
  });
}

class WeakTopic {
  final String topic;
  final double accuracy;

  WeakTopic({
    required this.topic,
    required this.accuracy,
  });
}

class AdaptivePathLoadResult {
  final List<PathNode> nodes;
  final bool isOfflineFallback;
  final bool isCached;
  final bool isRetrying;

  const AdaptivePathLoadResult({
    required this.nodes,
    required this.isOfflineFallback,
    required this.isCached,
    required this.isRetrying,
  });
}

/// Adaptive Learning Service
class AdaptiveLearningService {
  final ApiService apiService;
  final SrsService srsService;
  final RetryExecutor _retryExecutor;

  static const String _pathCacheKey = 'adaptive.path.cache.v1';
  static const String _practiceCacheKey = 'adaptive.practice.cache.v1';

  AdaptiveLearningService({
    required this.apiService,
    required this.srsService,
    RetryExecutor? retryExecutor,
  }) : _retryExecutor = retryExecutor ??
            RetryExecutor(
              canRetry: () async => ConnectivityService.instance.isOnline,
            );

  Future<AdaptivePracticeData> fetchPracticeData() async {
    final cachedPractice = await _readMapCache(_practiceCacheKey);
    try {
      final result = await apiService.getAdaptiveRecommendationsResult();
      final response = result.data;
      if (response != null && response.isNotEmpty) {
        await _writeMapCache(_practiceCacheKey, response);
        return AdaptivePracticeData(
          topicId: _asInt(response['topicId']),
          topic: (response['topic'] ?? response['topicName'] ?? 'Practice')
              .toString(),
          difficulty:
              (response['difficulty'] ?? response['targetDifficulty'] ?? 'Medium')
                  .toString(),
          questionCount: _asInt(response['questionCount']) ?? 10,
          confidence: (response['confidence'] ?? 'Adaptive').toString(),
        );
      }
    } catch (_) {}

    if (cachedPractice != null) {
      return AdaptivePracticeData(
        topicId: _asInt(cachedPractice['topicId']),
        topic: (cachedPractice['topic'] ?? cachedPractice['topicName'] ?? 'Practice')
            .toString(),
        difficulty: (cachedPractice['difficulty'] ?? 'Medium').toString(),
        questionCount: _asInt(cachedPractice['questionCount']) ?? 10,
        confidence: 'Cached',
      );
    }

    try {
      final reviewItems = await apiService.getAdaptiveReview();
      if (reviewItems != null && reviewItems.isNotEmpty) {
        return AdaptivePracticeData(
          topic: 'Review',
          difficulty: 'Medium',
          questionCount: reviewItems.length,
          confidence: 'Review',
        );
      }
    } catch (_) {}

    try {
      final srsData = await srsService.fetchDailySrsQuestions();
      return AdaptivePracticeData(
        topic: 'Daily review',
        difficulty: 'Medium',
        questionCount: srsData.length,
        confidence: 'Fallback',
      );
    } catch (_) {}

    return AdaptivePracticeData(
      topic: 'Practice',
      difficulty: 'Medium',
      questionCount: 10,
      confidence: 'Default',
    );
  }

  Future<List<WeakTopic>> fetchWeakTopics() async {
    final items = await apiService.getTopicsProgress();
    if (items == null || items.isEmpty) {
      return [];
    }

    final result = <WeakTopic>[];
    for (final item in items) {
      if (item is! Map) continue;
      final topic = (item['name'] ?? item['topicName'] ?? '').toString().trim();
      if (topic.isEmpty) continue;
      final accuracy = _asDouble(item['accuracy'] ?? item['progress']) ?? 0;
      if (accuracy < 70) {
        result.add(WeakTopic(topic: topic, accuracy: accuracy));
      }
    }
    result.sort((a, b) => a.accuracy.compareTo(b.accuracy));
    return result;
  }

  Future<AdaptiveSession> startSession({int? topicId, String? topic}) async {
    final response = await apiService.startAdaptiveSession(
      topicId: topicId,
      topic: topic,
    );
    final questionIds = <int>[];
    final rawItems = response?['questions'];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          final id = _asInt(raw['questionId'] ?? raw['id']);
          if (id != null) questionIds.add(id);
        } else {
          final id = _asInt(raw);
          if (id != null) questionIds.add(id);
        }
      }
    }
    return AdaptiveSession(
      sessionId: (response?['sessionId'] ?? '').toString(),
      questionIds: questionIds,
      topic: (response?['topic'] ?? topic ?? 'Practice').toString(),
      difficulty: (response?['difficulty'] ?? 'Medium').toString(),
    );
  }

  Future<AdaptiveRecommendation> getNextRecommendation() async {
    final result = await apiService.getAdaptiveRecommendationsResult();
    final response = result.data;
    if (response == null || response.isEmpty) {
      final cached = await _readMapCache(_practiceCacheKey);
      if (cached != null) {
        return AdaptiveRecommendation(
          topicId: _asInt(cached['topicId']),
          topic: (cached['topic'] ?? cached['topicName'] ?? 'Practice')
              .toString(),
          difficulty: (cached['difficulty'] ?? 'Medium').toString(),
          questionCount: _asInt(cached['questionCount']) ?? 10,
          reasoning: 'Cached recommendation',
        );
      }
      final practice = await fetchPracticeData();
      return AdaptiveRecommendation(
        topicId: practice.topicId,
        topic: practice.topic,
        difficulty: practice.difficulty,
        questionCount: practice.questionCount,
        reasoning: 'Fallback recommendation',
      );
    }
    return AdaptiveRecommendation(
      topicId: _asInt(response['topicId']),
      topic: (response['topic'] ?? response['topicName'] ?? 'Practice')
          .toString(),
      difficulty:
          (response['difficulty'] ?? response['targetDifficulty'] ?? 'Medium')
              .toString(),
      questionCount: _asInt(response['questionCount']) ?? 10,
      reasoning: (response['reasoning'] ?? 'Continue with recommended practice')
          .toString(),
    );
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Learning Path
  // ---------------------------------------------------------------------------

  /// Fetches the learning path.
  ///
  /// Priority:
  ///   1. `GET /adaptive/path` on the backend.
  ///   2. Derived path built from progress topics + SRS due count.
  ///
  /// The caller (provider) should cache the last successful result for offline.
  Future<AdaptivePathLoadResult> loadAdaptivePath({
    required List<Map<String, dynamic>> fallbackTopics,
    required int fallbackDueCount,
    required int userLevel,
    bool forceRefresh = false,
  }) async {
    var isRetrying = false;

    final cachedNodes = forceRefresh ? const <PathNode>[] : await _readPathCache();

    try {
      final raw = await _retryExecutor.run<Map<String, dynamic>>(
        () async {
          final result = await apiService.getAdaptivePathResult();
          if (result.isRateLimited && result.retryAfter != null) {
            throw TimeoutException(
              'Rate limited. Retry after ${result.retryAfter}',
            );
          }
          // 4xx errors are permanent client errors — retrying will not help.
          final statusCode = result.statusCode ?? 0;
          if (statusCode >= 400 && statusCode < 500) {
            throw Exception(
              'HTTP $statusCode from /adaptive/path — not retrying',
            );
          }
          final payload = result.data;
          if (payload == null) {
            throw StateError('Adaptive path endpoint returned no data');
          }
          final nodes = payload['nodes'];
          if (nodes is! List || nodes.isEmpty) {
            throw StateError('Adaptive path response did not include nodes');
          }
          return payload;
        },
        policy: const RetryPolicy(maxAttempts: 3),
        retryIf: (error) =>
            error is TimeoutException ||
            error is StateError ||
            error.toString().contains('SocketException'),
        onRetry: (attempt, delay, error) {
          isRetrying = true;
          debugPrint(
            '[AdaptiveLearningService] retry $attempt in ${delay.inMilliseconds}ms: $error',
          );
        },
      );

      final list = raw['nodes'] as List<dynamic>;
      final nodes = list
          .whereType<Map<String, dynamic>>()
          .map(PathNode.fromJson)
          .toList(growable: false);
      await _writePathCache(nodes);

      return AdaptivePathLoadResult(
        nodes: nodes,
        isOfflineFallback: false,
        isCached: false,
        isRetrying: isRetrying,
      );
    } catch (e) {
      debugPrint('[AdaptiveLearningService] /adaptive/path failed: $e');
    }

    if (cachedNodes.isNotEmpty) {
      return AdaptivePathLoadResult(
        nodes: cachedNodes,
        isOfflineFallback: true,
        isCached: true,
        isRetrying: isRetrying,
      );
    }

    final fallbackNodes = _buildFallbackPath(
      topics: fallbackTopics,
      dueReviewCount: fallbackDueCount,
      userLevel: userLevel,
    );
    await _writePathCache(fallbackNodes);
    return AdaptivePathLoadResult(
      nodes: fallbackNodes,
      isOfflineFallback: true,
      isCached: false,
      isRetrying: isRetrying,
    );
  }

  Future<({List<PathNode> nodes, bool isOfflineFallback})> fetchLearningPath({
    required List<Map<String, dynamic>> fallbackTopics,
    required int fallbackDueCount,
    required int userLevel,
  }) async {
    final result = await loadAdaptivePath(
      fallbackTopics: fallbackTopics,
      fallbackDueCount: fallbackDueCount,
      userLevel: userLevel,
    );
    return (nodes: result.nodes, isOfflineFallback: result.isOfflineFallback);
  }

  /// Returns how many SRS items are due for review.
  Future<int> fetchDueReviewCount() async {
    try {
      final items = await srsService.fetchDailySrsQuestions();
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  /// Derives a learning-path node list from topic progress + SRS due count.
  ///
  /// Algorithm:
  ///   • A review node is prepended when [dueReviewCount] > 0.
  ///   • Topics become lesson nodes in ascending mastery order (weakest first).
  ///   • A checkpoint node is inserted every 4 lessons.
  ///   • Locked topics produce locked nodes.
  List<PathNode> _buildFallbackPath({
    required List<Map<String, dynamic>> topics,
    required int dueReviewCount,
    required int userLevel,
  }) {
    final nodes = <PathNode>[];

    // Review node when SRS items are due
    if (dueReviewCount > 0) {
      nodes.add(PathNode(
        id: 'review_daily',
        type: PathNodeType.review,
        topicId: 0,
        topicName: 'Daily Review',
        difficulty: DifficultyLevel.medium,
        mastery: 0,
        state: PathNodeState.available,
        recommendationReason: '$dueReviewCount items need review today.',
        confidence: ConfidenceLevel.high,
        xpReward: 15,
        estimatedMinutes: dueReviewCount.clamp(3, 15),
        dueReviewCount: dueReviewCount,
      ));
    }

    // Sort topics: weakest mastery first, locked last
    final sorted = List<Map<String, dynamic>>.from(topics);
    sorted.sort((a, b) {
      final aLocked = a['unlocked'] == false;
      final bLocked = b['unlocked'] == false;
      if (aLocked != bLocked) return aLocked ? 1 : -1;
      final aAcc = (_asDouble(a['accuracy'] ?? a['progress']) ?? 0);
      final bAcc = (_asDouble(b['accuracy'] ?? b['progress']) ?? 0);
      return aAcc.compareTo(bAcc);
    });

    int lessonIndex = 0;
    for (final topic in sorted) {
      final topicId = _asInt(topic['id'] ?? topic['topicId']) ?? 0;
      final name = (topic['name'] ?? topic['topicName'] ?? 'Topic').toString();
      final accuracy = (_asDouble(topic['accuracy'] ?? topic['progress']) ?? 0);
      final locked = topic['unlocked'] == false;
      final mastery = accuracy.clamp(0.0, 100.0);

      // Insert a checkpoint every 4 lessons
      if (lessonIndex > 0 && lessonIndex % 4 == 0) {
        nodes.add(PathNode(
          id: 'checkpoint_$lessonIndex',
          type: PathNodeType.checkpoint,
          topicId: topicId,
          topicName: 'Checkpoint ${lessonIndex ~/ 4}',
          difficulty: DifficultyLevel.medium,
          mastery: 0,
          state: locked ? PathNodeState.locked : PathNodeState.available,
          confidence: ConfidenceLevel.med,
          xpReward: 50,
          estimatedMinutes: 8,
        ));
      }

      final nodeState = locked
          ? PathNodeState.locked
          : (mastery >= 80 ? PathNodeState.completed : PathNodeState.available);

      nodes.add(PathNode(
        id: 'lesson_$topicId',
        type: PathNodeType.lesson,
        topicId: topicId,
        topicName: name,
        difficulty: _difficultyFromMastery(mastery),
        mastery: mastery,
        state: nodeState,
        recommendationReason: _reasonFromMastery(mastery, name),
        confidence: _confidenceFromMastery(mastery),
        xpReward: 20,
        estimatedMinutes: 5,
      ));

      lessonIndex++;
    }

    return nodes;
  }

  DifficultyLevel _difficultyFromMastery(double mastery) {
    if (mastery < 40) return DifficultyLevel.easy;
    if (mastery < 70) return DifficultyLevel.medium;
    return DifficultyLevel.hard;
  }

  ConfidenceLevel _confidenceFromMastery(double mastery) {
    if (mastery < 40) return ConfidenceLevel.low;
    if (mastery < 70) return ConfidenceLevel.med;
    return ConfidenceLevel.high;
  }

  String _reasonFromMastery(double mastery, String name) {
    if (mastery < 40) return 'You need more practice on $name.';
    if (mastery < 70) return 'Keep building your $name skills.';
    return 'Great progress on $name! Push to mastery.';
  }

  Future<void> _writeMapCache(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> _readMapCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _writePathCache(List<PathNode> nodes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(nodes.map((node) => node.toJson()).toList());
    await prefs.setString(_pathCacheKey, encoded);
  }

  Future<List<PathNode>> _readPathCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pathCacheKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PathNode.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
