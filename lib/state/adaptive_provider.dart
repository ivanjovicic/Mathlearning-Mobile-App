import 'package:flutter/material.dart';
import '../models/path_node.dart';
import '../services/analytics/adaptive_analytics_service.dart';
import '../services/adaptive_learning_service.dart';
import 'progress_provider.dart';

class AdaptiveProvider with ChangeNotifier {
  final AdaptiveLearningService adaptiveService;

  AdaptiveProvider({required this.adaptiveService});

  bool _isLoading = false;
  String? _error;
  AdaptivePracticeData? _practiceData;
  List<WeakTopic> _weakTopics = const [];
  AdaptiveRecommendation? _recommendation;
  AdaptiveSession? _adaptiveSession;
  List<PathNode> _pathNodes = const [];
  bool _isOfflineFallback = false;
  bool _isCached = false;
  bool _isRetrying = false;
  int _userLevel = 1;
  List<Map<String, dynamic>> _cachedTopics = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  AdaptivePracticeData? get practiceData => _practiceData;
  List<WeakTopic> get weakTopics => _weakTopics;
  AdaptiveRecommendation? get recommendation => _recommendation;
  AdaptiveSession? get adaptiveSession => _adaptiveSession;
  List<PathNode> get pathNodes => _pathNodes;
  bool get isOfflineFallback => _isOfflineFallback;
  bool get isCached => _isCached;
  bool get isRetrying => _isRetrying;

  void updateFromProgress(ProgressProvider progress) {
    _userLevel = progress.level;
    _cachedTopics = progress.topics
        .map((topic) => {
              'id': topic.topicId,
              'name': topic.name,
              'accuracy': 0.0,
              'unlocked': topic.unlocked,
            })
        .toList(growable: false);
  }

  Future<void> loadDashboard() async {
    _setLoading(true);
    _error = null;
    try {
      final results = await Future.wait<dynamic>([
        adaptiveService.fetchPracticeData(),
        adaptiveService.fetchWeakTopics(),
        adaptiveService.getNextRecommendation(),
      ]);
      _practiceData = results[0] as AdaptivePracticeData;
      _weakTopics = results[1] as List<WeakTopic>;
      _recommendation = results[2] as AdaptiveRecommendation;
      AdaptiveAnalyticsService.instance.logEvent(
        AdaptiveAnalyticsService.adaptivePathLoaded,
        {'screen': 'adaptive_dashboard'},
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPracticeData() async {
    _practiceData = await adaptiveService.fetchPracticeData();
    notifyListeners();
  }

  Future<void> loadWeakTopics() async {
    _weakTopics = await adaptiveService.fetchWeakTopics();
    notifyListeners();
  }

  Future<void> loadRecommendation() async {
    _recommendation = await adaptiveService.getNextRecommendation();
    notifyListeners();
  }

  Future<void> startSession({int? topicId, String? topic}) async {
    _setLoading(true);
    _error = null;
    try {
      _adaptiveSession = await adaptiveService.startSession(
        topicId: topicId,
        topic: topic,
      );
      AdaptiveAnalyticsService.instance.logEvent(
        AdaptiveAnalyticsService.adaptivePracticeStarted,
        {
          'topicId': topicId,
          'topic': topic ?? _adaptiveSession?.topic,
          'difficulty': _adaptiveSession?.difficulty,
        },
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAdaptivePath({bool forceRefresh = false}) async {
    _setLoading(true);
    _error = null;
    try {
      final dueCount = await adaptiveService.fetchDueReviewCount();
      final result = await adaptiveService.loadAdaptivePath(
        fallbackTopics: _cachedTopics,
        fallbackDueCount: dueCount,
        userLevel: _userLevel,
        forceRefresh: forceRefresh,
      );
      _pathNodes = result.nodes;
      _isOfflineFallback = result.isOfflineFallback;
      _isCached = result.isCached;
      _isRetrying = result.isRetrying;
      AdaptiveAnalyticsService.instance.logEvent(
        AdaptiveAnalyticsService.adaptivePathLoaded,
        {
          'isOfflineFallback': _isOfflineFallback,
          'isCached': _isCached,
          'isRetrying': _isRetrying,
          'nodeCount': _pathNodes.length,
        },
      );
      if (_isRetrying) {
        AdaptiveAnalyticsService.instance.logEvent(
          AdaptiveAnalyticsService.adaptiveRetryTriggered,
          {'screen': 'adaptive_provider'},
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
