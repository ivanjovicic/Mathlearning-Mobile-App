import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/daily_mission.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/features/learning_map/models/practice_recommendation.dart';
import 'package:mathlearning/features/learning_map/models/quest.dart';
import 'package:mathlearning/features/learning_map/models/skill_mastery.dart';
import 'package:mathlearning/features/learning_map/models/skill_node_state.dart';
import 'package:mathlearning/features/learning_map/services/adaptive_retry_helper.dart';
import 'package:mathlearning/features/learning_map/services/learning_map_service.dart';
import 'package:mathlearning/services/analytics/adaptive_analytics_service.dart';
import 'package:mathlearning/services/connectivity_service.dart';

class LearningMapProvider extends ChangeNotifier {
  LearningMapProvider({
    required LearningMapDataSource service,
    AdaptiveRetryHelper? retryHelper,
    AdaptiveAnalyticsService? analytics,
  }) : _service = service,
       _retryHelper = retryHelper ?? const AdaptiveRetryHelper(),
       _analytics = analytics ?? AdaptiveAnalyticsService.instance;

  static const _pathCachePrefix = 'learning_map.path.v1.';
  static const _masteryCachePrefix = 'learning_map.mastery.v1.';
  static const _weaknessCachePrefix = 'learning_map.weakness.v1.';
  static const _recommendationCachePrefix = 'learning_map.rec.v1.';
  static const _questCachePrefix = 'learning_map.quest.v1.';
  static const _missionCachePrefix = 'learning_map.mission.v1.';

  final LearningMapDataSource _service;
  final AdaptiveRetryHelper _retryHelper;
  final AdaptiveAnalyticsService _analytics;

  AdaptiveLearningPath? _path;
  List<SkillMastery> _mastery = const [];
  List<SkillMastery> _weakness = const [];
  List<PracticeRecommendation> _recommendations = const [];
  List<Quest> _quests = const [];
  List<DailyMission> _dailyMissions = const [];

  bool _loading = false;
  String? _error;
  bool _isOfflineFallback = false;
  bool _isRetrying = false;
  DateTime? _lastUpdated;
  String? _currentUserId;
  int _lastRewardXp = 0;
  double _lastMasteryDelta = 0;

  AdaptiveLearningPath? get path => _path;
  List<SkillMastery> get mastery => _mastery;
  List<SkillMastery> get weakness => _weakness;
  List<PracticeRecommendation> get recommendations => _recommendations;
  List<Quest> get quests => _quests;
  List<DailyMission> get dailyMissions => _dailyMissions;
  bool get loading => _loading;
  String? get error => _error;
  bool get isOfflineFallback => _isOfflineFallback;
  bool get isRetrying => _isRetrying;
  DateTime? get lastUpdated => _lastUpdated;
  int get lastRewardXp => _lastRewardXp;
  double get lastMasteryDelta => _lastMasteryDelta;

  SkillNode? get recommendedNode => _path?.recommendedNextNode;

  Future<void> loadAll(String userId) async {
    if (_loading) {
      return;
    }
    _currentUserId = userId;
    _loading = true;
    _error = null;
    _isOfflineFallback = false;
    _isRetrying = false;
    notifyListeners();

    await _loadGamification(userId);

    final isOnline = ConnectivityService.instance.isOnline;
    if (!isOnline) {
      final loaded = await _loadFromCache(userId);
      _loading = false;
      _isOfflineFallback = loaded;
      _error = loaded ? null : 'No internet connection and no cached data.';
      notifyListeners();
      return;
    }

    final pathFuture = _retryHelper.run(() => _service.fetchPath(userId));
    final masteryFuture = _retryHelper.run(() => _service.fetchMastery(userId));
    final weaknessFuture = _retryHelper.run(
      () => _service.fetchWeakness(userId),
    );
    final recommendationsFuture = _retryHelper.run(
      () => _service.fetchRecommendations(userId),
    );

    final results = await Future.wait([
      pathFuture,
      masteryFuture,
      weaknessFuture,
      recommendationsFuture,
    ]);

    final pathResult = results[0] as RetryResult<AdaptiveLearningPath>;
    final masteryResult = results[1] as RetryResult<List<SkillMastery>>;
    final weaknessResult = results[2] as RetryResult<List<SkillMastery>>;
    final recommendationResult =
        results[3] as RetryResult<List<PracticeRecommendation>>;

    _isRetrying =
        pathResult.usedRetry ||
        masteryResult.usedRetry ||
        weaknessResult.usedRetry ||
        recommendationResult.usedRetry;

    final successful =
        pathResult.result.data != null &&
        masteryResult.result.data != null &&
        recommendationResult.result.data != null;

    if (successful) {
      _path = pathResult.result.data;
      _mastery = masteryResult.result.data ?? const [];
      _weakness = weaknessResult.result.data ?? const [];
      _recommendations = _normalizeRecommendations(
        recommendationResult.result.data ?? const [],
      );
      _lastUpdated = DateTime.now();
      _isOfflineFallback = false;
      _error = null;
      _buildGamification();
      await _writeToCache(userId);
      await _saveGamification(userId);
      _analytics.logEvent(AdaptiveAnalyticsService.adaptivePathLoaded, {
        'node_count': _path?.nodes.length ?? 0,
        'offline_fallback': false,
      });
    } else {
      final loaded = await _loadFromCache(userId);
      _isOfflineFallback = loaded;
      _error = loaded
          ? _firstError(results)
          : (_firstError(results) ?? 'Unable to load learning map.');
      if (_path != null && _quests.isEmpty && _dailyMissions.isEmpty) {
        _buildGamification();
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> refresh(String userId) async {
    await loadAll(userId);
  }

  SkillNodeState getNodeState(SkillNode node) {
    if (node.isLocked) {
      return SkillNodeState.locked;
    }
    if (_path?.recommendedNext == node.id) {
      return SkillNodeState.recommended;
    }
    if (getNodeProgress(node) >= 0.85) {
      return SkillNodeState.mastered;
    }
    return SkillNodeState.learning;
  }

  double getNodeProgress(SkillNode node) => node.mastery01;

  PracticeLaunchPlan buildLaunchPlanForNode(SkillNode node) {
    final recommendation = _findRecommendationForNode(node);
    final source = _resolveSourceForNode(node);
    final practiceId = recommendation?.practiceId.trim() ?? '';
    return PracticeLaunchPlan(
      userId: _currentUserId ?? '',
      nodeId: node.id,
      skillTitle: node.title,
      topicId: node.topicId,
      subtopicId: node.subtopicId,
      difficulty:
          recommendation?.recommendedDifficulty ?? node.recommendedDifficulty,
      source: source,
      practiceId: practiceId.isEmpty ? node.id : practiceId,
      targetQuestions: 10,
    );
  }

  SkillNode? findNodeById(String nodeId) {
    final nodes = _path?.nodes;
    if (nodes == null) {
      return null;
    }
    for (final node in nodes) {
      if (node.id == nodeId) {
        return node;
      }
    }
    return null;
  }

  Future<void> completePractice({
    required PracticeLaunchPlan plan,
    required int xpEarned,
    required double masteryDelta,
    required double accuracy,
    String? recommendedNextNodeId,
  }) async {
    _lastRewardXp = xpEarned;
    _lastMasteryDelta = masteryDelta;

    final currentPath = _path;
    if (currentPath != null) {
      final updated = currentPath.withUpdatedNode(plan.nodeId, masteryDelta);
      _path = updated.copyWith(
        recommendedNext: recommendedNextNodeId ?? updated.recommendedNext,
        generatedAt: DateTime.now().toUtc(),
      );
    }
    _updateMasteryAfterPractice(plan, masteryDelta);
    _updateGamificationAfterPractice(plan, accuracy);

    final userId = _currentUserId;
    if (userId != null && userId.isNotEmpty) {
      await _writeToCache(userId);
      await _saveGamification(userId);
    }

    _analytics.logEvent(AdaptiveAnalyticsService.adaptiveSessionCompleted, {
      'node_id': plan.nodeId,
      'accuracy': accuracy,
      'xp': xpEarned,
    });
    notifyListeners();
  }

  PracticeSource _resolveSourceForNode(SkillNode node) {
    final progress = getNodeProgress(node);
    if (progress >= 0.85) {
      return PracticeSource.review;
    }
    if (progress < 0.45) {
      return PracticeSource.weak;
    }
    return PracticeSource.recent;
  }

  PracticeRecommendation? _findRecommendationForNode(SkillNode node) {
    for (final recommendation in _recommendations) {
      if (recommendation.topicId == node.topicId) {
        return recommendation;
      }
    }
    return null;
  }

  void _buildGamification() {
    final weakTopics = _weakness
        .where((item) => item.mastery01 < 0.6)
        .toList(growable: false);
    final generatedQuests = <Quest>[];
    final generatedMissions = <DailyMission>[];

    if (weakTopics.isNotEmpty) {
      final weakest = weakTopics.first;
      final currentPercent = (weakest.mastery01 * 100).round();
      final completed = currentPercent >= 60;
      generatedQuests.add(
        Quest(
          id: 'quest_weak_${weakest.topicId}',
          title: 'Weakness Recovery',
          description: 'Improve ${weakest.topicName} mastery to 60%',
          target: weakest.topicName,
          progress: math.min(currentPercent, 60),
          goal: 60,
          rewardXp: 80,
          completed: completed,
        ),
      );
    }

    generatedQuests.add(
      Quest(
        id: 'quest_practice_3',
        title: 'Practice Sprint',
        description: 'Complete 3 adaptive practices',
        target: 'practice_count',
        progress: _questProgress('quest_practice_3', fallback: 0),
        goal: 3,
        rewardXp: 60,
        completed: _questProgress('quest_practice_3', fallback: 0) >= 3,
      ),
    );

    final recommended = _path?.recommendedNextNode;
    if (recommended != null) {
      generatedMissions.add(
        DailyMission(
          id: 'mission_next_skill',
          title: 'Complete next skill: ${recommended.title}',
          progress: _missionProgress('mission_next_skill', fallback: 0),
          goal: 1,
          rewardXp: 35,
          completed: _missionProgress('mission_next_skill', fallback: 0) >= 1,
        ),
      );
    }

    generatedMissions.add(
      DailyMission(
        id: 'mission_daily_practice',
        title: 'Finish 1 adaptive practice',
        progress: _missionProgress('mission_daily_practice', fallback: 0),
        goal: 1,
        rewardXp: 20,
        completed: _missionProgress('mission_daily_practice', fallback: 0) >= 1,
      ),
    );

    _quests = generatedQuests;
    _dailyMissions = generatedMissions;
  }

  int _questProgress(String id, {required int fallback}) {
    for (final quest in _quests) {
      if (quest.id == id) {
        return quest.progress;
      }
    }
    return fallback;
  }

  int _missionProgress(String id, {required int fallback}) {
    for (final mission in _dailyMissions) {
      if (mission.id == id) {
        return mission.progress;
      }
    }
    return fallback;
  }

  void _updateMasteryAfterPractice(
    PracticeLaunchPlan plan,
    double masteryDelta,
  ) {
    var updated = false;
    final next = <SkillMastery>[];
    for (final item in _mastery) {
      if (item.topicId == plan.topicId) {
        final nextValue = math.min(
          1.0,
          math.max(0.0, item.mastery01 + masteryDelta),
        );
        next.add(
          SkillMastery(
            topicId: item.topicId,
            topicName: item.topicName,
            masteryProbability: nextValue,
          ),
        );
        updated = true;
      } else {
        next.add(item);
      }
    }

    if (!updated) {
      next.add(
        SkillMastery(
          topicId: plan.topicId,
          topicName: plan.skillTitle,
          masteryProbability: masteryDelta.clamp(0.0, 1.0),
        ),
      );
    }

    _mastery = List.unmodifiable(next);
  }

  void _updateGamificationAfterPractice(
    PracticeLaunchPlan plan,
    double accuracy,
  ) {
    _quests = _quests
        .map((quest) {
          if (quest.id == 'quest_practice_3') {
            final nextProgress = math.min(quest.goal, quest.progress + 1);
            return quest.copyWith(
              progress: nextProgress,
              completed: nextProgress >= quest.goal,
            );
          }

          if (quest.id == 'quest_weak_${plan.topicId}') {
            final current = ((_topicMastery(plan.topicId) ?? 0) * 100).round();
            final nextProgress = math.min(quest.goal, current);
            return quest.copyWith(
              progress: nextProgress,
              completed: nextProgress >= quest.goal,
            );
          }

          return quest;
        })
        .toList(growable: false);

    _dailyMissions = _dailyMissions
        .map((mission) {
          if (mission.id == 'mission_daily_practice') {
            final nextProgress = math.min(mission.goal, mission.progress + 1);
            return mission.copyWith(
              progress: nextProgress,
              completed: nextProgress >= mission.goal,
            );
          }
          if (mission.id == 'mission_next_skill' &&
              plan.nodeId == _path?.recommendedNext) {
            return mission.copyWith(progress: 1, completed: true);
          }
          if (mission.id == 'mission_next_skill' && accuracy >= 0.7) {
            final nextProgress = math.min(mission.goal, mission.progress + 1);
            return mission.copyWith(
              progress: nextProgress,
              completed: nextProgress >= mission.goal,
            );
          }
          return mission;
        })
        .toList(growable: false);
  }

  double? _topicMastery(int topicId) {
    for (final item in _mastery) {
      if (item.topicId == topicId) {
        return item.mastery01;
      }
    }
    return null;
  }

  Future<bool> _loadFromCache(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final pathRaw = prefs.getString('$_pathCachePrefix$userId');
    final masteryRaw = prefs.getString('$_masteryCachePrefix$userId');
    final weaknessRaw = prefs.getString('$_weaknessCachePrefix$userId');
    final recommendationRaw = prefs.getString(
      '$_recommendationCachePrefix$userId',
    );

    if (pathRaw == null || masteryRaw == null || recommendationRaw == null) {
      return false;
    }

    try {
      final decodedPath = jsonDecode(pathRaw);
      final decodedMastery = jsonDecode(masteryRaw);
      final decodedWeakness = weaknessRaw == null
          ? const []
          : jsonDecode(weaknessRaw);
      final decodedRecommendation = jsonDecode(recommendationRaw);

      if (decodedPath is! Map ||
          decodedMastery is! List ||
          decodedRecommendation is! List) {
        return false;
      }

      _path = AdaptiveLearningPath.fromJson(
        Map<String, dynamic>.from(decodedPath),
      );
      _mastery = decodedMastery
          .whereType<Map>()
          .map((item) => SkillMastery.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
      _weakness = decodedWeakness is List
          ? decodedWeakness
                .whereType<Map>()
                .map(
                  (item) =>
                      SkillMastery.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList(growable: false)
          : const [];
      _recommendations = decodedRecommendation
          .whereType<Map>()
          .map(
            (item) => PracticeRecommendation.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
      _buildGamification();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _writeToCache(String userId) async {
    final path = _path;
    if (path == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_pathCachePrefix$userId',
      jsonEncode(path.toJson()),
    );
    await prefs.setString(
      '$_masteryCachePrefix$userId',
      jsonEncode(_mastery.map((item) => item.toJson()).toList(growable: false)),
    );
    await prefs.setString(
      '$_weaknessCachePrefix$userId',
      jsonEncode(
        _weakness.map((item) => item.toJson()).toList(growable: false),
      ),
    );
    await prefs.setString(
      '$_recommendationCachePrefix$userId',
      jsonEncode(
        _recommendations.map((item) => item.toJson()).toList(growable: false),
      ),
    );
  }

  Future<void> _loadGamification(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawQuest = prefs.getString('$_questCachePrefix$userId');
    final rawMission = prefs.getString('$_missionCachePrefix$userId');
    if (rawQuest == null || rawMission == null) {
      return;
    }

    try {
      final questList = jsonDecode(rawQuest);
      final missionList = jsonDecode(rawMission);
      if (questList is List) {
        _quests = questList
            .whereType<Map>()
            .map((item) => Quest.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false);
      }
      if (missionList is List) {
        _dailyMissions = missionList
            .whereType<Map>()
            .map(
              (item) => DailyMission.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
      }
    } catch (_) {
      _quests = const [];
      _dailyMissions = const [];
    }
  }

  Future<void> _saveGamification(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_questCachePrefix$userId',
      jsonEncode(_quests.map((item) => item.toJson()).toList(growable: false)),
    );
    await prefs.setString(
      '$_missionCachePrefix$userId',
      jsonEncode(
        _dailyMissions.map((item) => item.toJson()).toList(growable: false),
      ),
    );
  }

  List<PracticeRecommendation> _normalizeRecommendations(
    List<PracticeRecommendation> items,
  ) {
    if (items.isEmpty) {
      return const [];
    }
    return items
        .map((item) {
          final fallbackId = item.practiceId.trim().isEmpty
              ? 'topic_${item.topicId}_practice'
              : item.practiceId;
          return PracticeRecommendation(
            topicId: item.topicId,
            topicName: item.topicName,
            reason: item.reason,
            priorityScore: item.priorityScore,
            recommendedDifficulty: item.recommendedDifficulty,
            practiceId: fallbackId,
          );
        })
        .toList(growable: false);
  }

  String? _firstError(List<dynamic> results) {
    for (final result in results) {
      if (result is RetryResult<AdaptiveLearningPath>) {
        final message = result.result.error?.message;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      if (result is RetryResult<List<SkillMastery>>) {
        final message = result.result.error?.message;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      if (result is RetryResult<List<PracticeRecommendation>>) {
        final message = result.result.error?.message;
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    }
    return null;
  }
}
