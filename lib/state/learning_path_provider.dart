import 'package:flutter/foundation.dart';
import '../models/path_node.dart';
import '../services/adaptive_learning_service.dart';
import '../services/analytics/adaptive_analytics_service.dart';
import '../state/progress_provider.dart';

/// Manages the state of the Learning Path screen.
///
/// Data sources (hybrid mode):
///   1. Backend `GET /adaptive/path`
///   2. Derived from [ProgressProvider.topics] + SRS due reviews
///   3. Cached last-successful path for offline access
///
/// All heavy computation runs in [loadPath] — the build tree only reads
/// the resulting immutable [nodes] list.
class LearningPathProvider extends ChangeNotifier {
  final AdaptiveLearningService _service;

  LearningPathProvider({required AdaptiveLearningService service})
      : _service = service;

  // --------------------------------------------------------------------------
  // State
  // --------------------------------------------------------------------------

  bool _isLoading = false;
  String? _error;
  List<PathNode> _nodes = const [];
  bool _isOfflineFallback = false;
  bool _isCached = false;
  bool _isRetrying = false;
  int _userLevel = 1;

  /// Cached topics from the last [ProgressProvider] update — used by
  /// [loadPath] so the provider doesn't need to hold a hard reference to
  /// [ProgressProvider].
  List<Map<String, dynamic>> _cachedTopics = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PathNode> get nodes => _nodes;
  bool get isOfflineFallback => _isOfflineFallback;
  bool get isCached => _isCached;
  bool get isRetrying => _isRetrying;

  /// The first node the user should work on next.
  PathNode? get recommended {
    // Prefer an in-progress node
    PathNode? first;
    for (final n in _nodes) {
      if (n.state == PathNodeState.inProgress) return n;
      if (first == null && n.state == PathNodeState.available) first = n;
    }
    return first;
  }

  int get dueReviewCount {
    for (final n in _nodes) {
      if (n.type == PathNodeType.review) return n.dueReviewCount;
    }
    return 0;
  }

  // --------------------------------------------------------------------------
  // Proxy-provider integration
  // --------------------------------------------------------------------------

  /// Called by [ChangeNotifierProxyProvider] when [ProgressProvider] updates.
  ///
  /// Snapshots the current topics list from [ProgressProvider].  A full
  /// [loadPath] is only triggered when topics have materially changed or when
  /// [_nodes] is empty.
  void updateFromProgress(ProgressProvider progress) {
    _userLevel = progress.level;
    final incoming = progress.topics
        .map((t) => {
              'id': t.topicId,
              'name': t.name,
              'accuracy': 0.0, // TopicProgress has no accuracy field yet
              'unlocked': t.unlocked,
            })
        .toList();

    final changed = incoming.length != _cachedTopics.length;
    _cachedTopics = incoming;

    if (_nodes.isEmpty || changed) {
      // Don't await — fire-and-forget so proxy update stays synchronous
      loadPath();
    }
  }

  // --------------------------------------------------------------------------
  // Loading
  // --------------------------------------------------------------------------

  Future<void> loadPath({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (!forceRefresh && _nodes.isNotEmpty) return;

    _setLoading(true);
    _error = null;
    _logEvent(AdaptiveAnalyticsService.adaptivePathLoaded);

    try {
      final dueCount = await _service.fetchDueReviewCount();
      final result = await _service.loadAdaptivePath(
        fallbackTopics: _cachedTopics,
        fallbackDueCount: dueCount,
        userLevel: _userLevel,
        forceRefresh: forceRefresh,
      );
      _nodes = result.nodes;
      _isOfflineFallback = result.isOfflineFallback;
      _isCached = result.isCached;
      _isRetrying = result.isRetrying;
      if (result.isRetrying) {
        _logEvent(AdaptiveAnalyticsService.adaptiveRetryTriggered, {
          'source': 'learning_path',
        });
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('[LearningPathProvider] loadPath error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // --------------------------------------------------------------------------
  // Mutations (optimistic UI updates after session completion)
  // --------------------------------------------------------------------------

  /// Updates a node's state and mastery after the user completes a session.
  ///
  /// Called from the quiz results flow so the path reflects updated progress
  /// immediately without a full reload.
  void markNodeCompleted(String nodeId, {double? newMastery}) {
    final idx = _nodes.indexWhere((n) => n.id == nodeId);
    if (idx < 0) return;

    final updated = _nodes[idx].copyWith(
      state: PathNodeState.completed,
      mastery: newMastery,
    );
    final mutable = List<PathNode>.from(_nodes);
    mutable[idx] = updated;
    _nodes = List.unmodifiable(mutable);
    _logEvent(AdaptiveAnalyticsService.adaptiveSessionCompleted, {
      'nodeId': nodeId,
    });
    notifyListeners();
  }

  /// Sets a node to [PathNodeState.inProgress] when a session begins.
  void markNodeStarted(String nodeId) {
    final idx = _nodes.indexWhere((n) => n.id == nodeId);
    if (idx < 0) return;

    final updated = _nodes[idx].copyWith(state: PathNodeState.inProgress);
    final mutable = List<PathNode>.from(_nodes);
    mutable[idx] = updated;
    _nodes = List.unmodifiable(mutable);
    _logEvent(AdaptiveAnalyticsService.adaptivePracticeStarted, {
      'nodeId': nodeId,
    });
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  /// Fire-and-forget analytics stub.  Replace with your analytics service.
  void _logEvent(String name, [Map<String, dynamic>? params]) {
    debugPrint('[Analytics] $name ${params ?? ''}');
  }

  /// Convenience method used by the path screen for funnel events.
  void logEvent(String name, [Map<String, dynamic>? params]) =>
      _logEvent(name, params);
}
