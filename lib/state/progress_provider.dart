import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import '../services/progress_api_service.dart';
import '../services/user_scoped_storage.dart';
import '../models/topic_dto.dart';
import '../models/pending_local_progress.dart';
import '../services/offline_storage_service.dart';
import 'streak_freeze_provider.dart';
import 'dart:math' as math;

class ProgressProvider extends ChangeNotifier {
  final api = ApiService();
  // Injectable overview fetcher (tests can override this to simulate failures).
  final Future<ApiResult<Map<String, dynamic>>> Function()
  fetchProgressOverview;
  // When true, allow demo fallback even for non-demo tokens (used in tests).
  final bool enableDemoFallback;
  // When true, indicates that no progress data is available (no cache + API failed)
  bool progressUnavailable = false;
  bool topicsUnavailable = false;
  bool _lastProgressLoadUsedFallback = false;
  Object? _lastProgressLoadError;

  final ProgressService _progressService = ProgressService.instance;
  static const Duration _reloadDebounce = Duration(seconds: 4);

  StreakFreezeProvider? _streakFreeze;
  DateTime? _lastStreakDay;
  ({int freezesUsed, bool streakBroken})? _pendingStreakRollEvent;

  String? token;
  String _userId = 'local';
  bool _isDemoMode = false;

  int level = 1;
  int xp = 0;
  int xpToNextLevel = 100;

  int streak = 0;
  int totalAttempts = 0;
  double accuracy = 0;

  // Permanent progress is server/cache-authoritative.
  // Local optimistic changes are stored as PendingProgressEvent entries and
  // exposed through display* getters until syncWithServer confirms them.
  PendingLocalProgress _pendingLocalProgress = PendingLocalProgress.empty;

  VoidCallback? onLevelUp; // callback za animaciju
  Future<void>? _loadProgressInFlight;
  Future<void>? _loadTopicsInFlight;
  Future<void>? _loadHomeDataInFlight;
  DateTime? _lastProgressLoadedAt;
  DateTime? _lastTopicsLoadedAt;

  void updateStreakFreezeProvider(StreakFreezeProvider provider) {
    _streakFreeze = provider;
  }

  void updateAuthContext({
    String? token,
    required bool isDemoMode,
    String? userId,
  }) {
    this.token = token;
    _isDemoMode = isDemoMode;
    _userId = UserScopedStorage.normalizeUserId(userId);
  }

  /// Clears in-memory user-visible progress so a newly authenticated user
  /// never briefly sees the previous user's stats.
  /// Does NOT touch the offline pending-events queue.
  void clearForUserSwitch() {
    level = 1;
    xp = 0;
    xpToNextLevel = 100;
    streak = 0;
    totalAttempts = 0;
    accuracy = 0;
    _lastStreakDay = null;
    topics = [];
    dailyProgress = {};
    _pendingLocalProgress = PendingLocalProgress.empty;
    _pendingStreakRollEvent = null;
    progressUnavailable = false;
    topicsUnavailable = false;
    _lastProgressLoadUsedFallback = false;
    _lastProgressLoadError = null;
    // Null the timestamps so the next loadProgress(forceRefresh: true) is
    // never short-circuited by the debounce / fresh-data check.
    _lastProgressLoadedAt = null;
    _lastTopicsLoadedAt = null;
    // Null the in-flight references so callers can start a fresh load.
    // The underlying coroutines, if still running, will complete harmlessly
    // since auth context was already updated via updateAuthContext.
    _loadProgressInFlight = null;
    _loadTopicsInFlight = null;
    _loadHomeDataInFlight = null;
    notifyListeners();
  }

  int _pendingEventSequence = 0;

  String _newPendingEventId(String type) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _pendingEventSequence += 1;
    return '${_userId}_${type}_${now}_$_pendingEventSequence';
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  String _dayKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool get isStreakDoneToday {
    final last = _lastStreakDay;
    final today = _dateOnly(DateTime.now());
    if (last != null && today == _dateOnly(last)) return true;
    final todayKey = _dayKey(today);
    return _pendingLocalProgress.hasPracticeRewardOnDay(todayKey);
  }

  bool get _isPersistedStreakDoneToday {
    final last = _lastStreakDay;
    if (last == null) return false;
    return _dateOnly(DateTime.now()) == _dateOnly(last);
  }

  DateTime? get lastStreakDay => _lastStreakDay;

  ({int freezesUsed, bool streakBroken})? takeStreakRollEvent() {
    final event = _pendingStreakRollEvent;
    _pendingStreakRollEvent = null;
    return event;
  }

  bool get hasPendingEvents =>
      _pendingLocalProgress.hasPending || _pendingStreakRollEvent != null;
  bool get lastProgressLoadUsedFallback => _lastProgressLoadUsedFallback;
  Object? get lastProgressLoadError => _lastProgressLoadError;

  // Display getters combine permanent state + pending optimistic deltas
  int get displayTotalAttempts =>
      totalAttempts + _pendingLocalProgress.pendingAnswerCount;

  double get displayAccuracy {
    final baseCorrect = (accuracy / 100.0 * totalAttempts).round();
    final pendingCorrect = _pendingLocalProgress.pendingCorrectAnswers;
    final total = displayTotalAttempts;
    if (total == 0) return 0.0;
    return ((baseCorrect + pendingCorrect) / total) * 100.0;
  }

  int get _baseTotalXp => (level - 1) * xpToNextLevel + xp;

  int get _pendingXpDelta => _pendingLocalProgress.xpDelta;

  Map<String, int> _levelXpFromTotalXp(int totalXp) {
    var lvl = 1;
    var leftover = totalXp;
    while (leftover >= xpToNextLevel) {
      leftover -= xpToNextLevel;
      lvl++;
    }
    return {'level': lvl, 'xp': leftover};
  }

  int get displayXp {
    final total = _baseTotalXp + _pendingXpDelta;
    return _levelXpFromTotalXp(total)['xp']!;
  }

  int get displayLevel {
    final total = _baseTotalXp + _pendingXpDelta;
    return _levelXpFromTotalXp(total)['level']!;
  }

  int get displayStreak {
    var value = streak;
    final pendingRoll = _pendingLocalProgress.latestStreakRoll;
    if (pendingRoll?.streakBroken == true) {
      value = 0;
    }
    final todayKey = _dayKey(_dateOnly(DateTime.now()));
    if (_pendingLocalProgress.hasPracticeRewardOnDay(todayKey)) {
      if (value <= 0) {
        value = 1;
      } else if (!_isPersistedStreakDoneToday) {
        value += 1;
      }
    }
    return value;
  }

  Future<void> _loadLastStreakDayFromPrefs() async {
    if (_lastStreakDay != null) return;
    final prefs = await SharedPreferences.getInstance();
    // TODO: legacy global key migration for authenticated users is intentionally conservative and should be removed after migration window.
    final ms =
        prefs.getInt(_lastStreakDayKey) ??
        (_userId == 'local'
            ? prefs.getInt('progress_last_streak_day_ms_v1')
            : null);
    if (ms == null) return;
    _lastStreakDay = _dateOnly(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  Future<void> _loadPendingEvents() async {
    final events = await OfflineStorageService.loadPendingProgressEventsForUser(
      userId: _userId,
    );
    _pendingLocalProgress = PendingLocalProgress.fromJsonList(events);
    _pendingStreakRollEvent = _pendingLocalProgress.latestStreakRoll;
  }

  Future<void> _cachePendingEventsLocally() async {
    await OfflineStorageService.cachePendingProgressEventsForUser(
      userId: _userId,
      events: _pendingLocalProgress.toJsonList(),
    );
  }

  Future<void> _clearPendingEventsLocally() async {
    _pendingLocalProgress = PendingLocalProgress.empty;
    _pendingStreakRollEvent = null;
    await OfflineStorageService.clearPendingProgressEventsForUser(
      userId: _userId,
    );
  }

  Future<void> _persistLastStreakDayToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = _lastStreakDay?.millisecondsSinceEpoch;
    if (ms == null) {
      await prefs.remove(_lastStreakDayKey);
      return;
    }
    await prefs.setInt(_lastStreakDayKey, ms);
  }

  /// If the user missed one or more days, attempt to consume streak freezes.
  /// Returns how many freezes were used and whether the streak was broken.
  Future<({int freezesUsed, bool streakBroken})> rollDailyStreakIfNeeded({
    DateTime? now,
  }) async {
    await _loadPendingEvents();
    await _loadLastStreakDayFromPrefs();

    final last = _lastStreakDay;
    if (last == null) {
      return (freezesUsed: 0, streakBroken: false);
    }

    final today = _dateOnly(now ?? DateTime.now());
    final diffDays = today.difference(_dateOnly(last)).inDays;
    if (diffDays <= 1) {
      return (freezesUsed: 0, streakBroken: false);
    }

    final missedDays = diffDays - 1;
    var freezesUsed = 0;

    if (_streakFreeze != null) {
      if (!_streakFreeze!.isLoaded) {
        await _streakFreeze!.load();
      }
      freezesUsed = await _streakFreeze!.consumeUpTo(missedDays);
      if (freezesUsed > 0) {
        _lastStreakDay = _dateOnly(last.add(Duration(days: freezesUsed)));
      }
    }

    final remainingMissedDays = math.max(0, missedDays - freezesUsed);
    // Do not mutate permanent streak here; register a pending streak roll event
    _pendingStreakRollEvent = (
      freezesUsed: freezesUsed,
      streakBroken: remainingMissedDays > 0,
    );
    final event = PendingProgressEvent(
      id: _newPendingEventId('streakRoll'),
      type: PendingProgressEventType.streakRoll,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      freezesUsed: freezesUsed,
      streakBroken: remainingMissedDays > 0,
    );
    _pendingLocalProgress = _pendingLocalProgress.add(event);

    // Persist pending event (do not write permanent progress)
    await _cachePendingEventsLocally();
    notifyListeners();
    return (freezesUsed: freezesUsed, streakBroken: remainingMissedDays > 0);
  }

  // ─── Optimistic update: apply XP / streak instantly ───

  /// Called by QuizProvider right after answering a question.
  /// Updates XP & streak immediately (works offline too).
  void applyAnswerResult({required bool isCorrect, int xpForQuestion = 10}) {
    final ev = PendingProgressEvent(
      id: _newPendingEventId('answer'),
      type: PendingProgressEventType.answer,
      isCorrect: isCorrect,
      xp: xpForQuestion,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );
    _pendingLocalProgress = _pendingLocalProgress.add(ev);
    // Persist pending events but do not mutate permanent progress
    unawaited(_cachePendingEventsLocally());
    notifyListeners();
  }

  // ─── Load progress (cache-first, then server) ───

  Future<void> loadProgress({bool forceRefresh = false}) {
    if (!forceRefresh && _loadProgressInFlight != null) {
      return _loadProgressInFlight!;
    }

    final now = DateTime.now();
    final hasFreshData =
        _lastProgressLoadedAt != null &&
        now.difference(_lastProgressLoadedAt!) < _reloadDebounce &&
        (totalAttempts > 0 || level > 1 || xp > 0);
    if (!forceRefresh && hasFreshData) {
      return Future.value();
    }

    final task = _loadProgressInternal().whenComplete(() {
      _loadProgressInFlight = null;
    });
    _loadProgressInFlight = task;
    return task;
  }

  ProgressProvider({
    Future<ApiResult<Map<String, dynamic>>> Function()? fetchProgressOverview,
    this.enableDemoFallback = false,
  }) : fetchProgressOverview =
           fetchProgressOverview ?? ProgressApiService().fetchOverviewResult;

  Future<void> _loadProgressInternal() async {
    // Reset unavailable flag at start of each load attempt
    progressUnavailable = false;
    _lastProgressLoadUsedFallback = false;
    _lastProgressLoadError = null;
    await _loadPendingEvents();
    // 1) Try from cache first (instant UI)
    var cached = await OfflineStorageService.getCachedUserProgressForUser(
      userId: _userId,
    );
    cached ??= await OfflineStorageService.loadCachedProgressV1ForUser(
      userId: _userId,
    );
    if (cached != null) {
      _applyFromCache(cached, notify: false);
    }

    // Ensure meta (like last streak day) is present even when SQLite cache is used.
    await _loadLastStreakDayFromPrefs();

    final allowDemoFallback = _isDemoMode || enableDemoFallback;

    // 2) Try from server to reconcile
    if (!_isDemoMode) {
      final result = await fetchProgressOverview();
      if (result.isSuccess && result.data != null) {
        _applyAuthoritativeRemoteProgress(result.data!);

        await _cacheProgressLocally();
        await rollDailyStreakIfNeeded();
        _lastProgressLoadedAt = DateTime.now();
        notifyListeners();
        return;
      }

      debugPrint(
        'Progress API failed: status=${result.statusCode} '
        'code=${result.errorCode} offline=${result.isOffline} '
        'auth=${result.isAuthError} msg=${result.error?.message}',
      );
      _lastProgressLoadError =
          result.error ?? result.errorCode ?? result.statusCode ?? 'unknown';

      // Already loaded from cache above, so UI still has data
      if (cached != null) {
        _lastProgressLoadUsedFallback = true;
        notifyListeners();
        return;
      }
      // No cache and API failed -> mark unavailable for real users
      if (!allowDemoFallback) {
        progressUnavailable = true;
        notifyListeners();
        return;
      }
    }

    // 3) Fallback demo data (explicit demo mode or tests-only fallback)
    if (cached == null) {
      if (allowDemoFallback) {
        _lastProgressLoadUsedFallback = true;
        totalAttempts = 15;
        accuracy = 75.0;
        streak = 3;
        xp = calculateXp(totalAttempts, accuracy);
      } else {
        // Nothing to show
        progressUnavailable = true;
        notifyListeners();
        return;
      }
    }

    await rollDailyStreakIfNeeded();
    _lastProgressLoadedAt = DateTime.now();
    notifyListeners();
  }

  // ─── Sync local progress with server (reconcile after offline) ───

  /// Push local state to server, then pull authoritative copy back.
  Future<void> syncWithServer() async {
    await _loadPendingEvents();

    final snapshot = _buildPendingAwareSnapshot();
    final localMap = {
      'level': snapshot.level,
      'xp': snapshot.xp,
      'streak': snapshot.streak,
      'totalAttempts': snapshot.totalAttempts,
      'accuracy': snapshot.accuracy,
      'pendingEvents': _pendingLocalProgress.toJsonList(),
    };

    try {
      final pushed = await _progressService.pushProgressResult(localMap);
      if (!pushed.isSuccess) {
        debugPrint(
          'syncWithServer push failed: status=${pushed.statusCode} '
          'code=${pushed.errorCode} offline=${pushed.isOffline} '
          'auth=${pushed.isAuthError} msg=${pushed.error?.message}',
        );
        return;
      }

      // Pull authoritative state from server
      final remote = await _progressService.fetchProgressResult();
      if (remote.isSuccess && remote.data != null) {
        _applyAuthoritativeRemoteProgress(remote.data!);
        await _clearPendingEventsLocally();
        await _cacheProgressLocally();
        notifyListeners();
      } else {
        debugPrint(
          'syncWithServer pull failed: status=${remote.statusCode} '
          'code=${remote.errorCode} offline=${remote.isOffline} '
          'auth=${remote.isAuthError} msg=${remote.error?.message}',
        );
      }
    } catch (e) {
      debugPrint('syncWithServer failed (will retry later): $e');
    }
  }

  // ─── Cache helpers ───

  void _applyFromCache(Map<String, dynamic> cached, {bool notify = true}) {
    level = cached['level'] ?? level;
    xp = cached['xp'] ?? xp;
    streak = cached['streak'] ?? streak;
    totalAttempts = cached['total_attempts'] ?? totalAttempts;
    accuracy = (cached['accuracy'] as num?)?.toDouble() ?? accuracy;
    final lastStreakMs = cached['last_streak_day_ms'];
    if (lastStreakMs is int) {
      _lastStreakDay = _dateOnly(
        DateTime.fromMillisecondsSinceEpoch(lastStreakMs),
      );
    } else if (lastStreakMs is num) {
      _lastStreakDay = _dateOnly(
        DateTime.fromMillisecondsSinceEpoch(lastStreakMs.toInt()),
      );
    }
    if (notify) notifyListeners();
  }

  Future<void> _cacheProgressLocally() async {
    final data = {
      'level': level,
      'xp': xp,
      'streak': streak,
      'total_attempts': totalAttempts,
      'accuracy': accuracy,
      'last_streak_day_ms': _lastStreakDay?.millisecondsSinceEpoch,
    };

    await OfflineStorageService.cacheUserProgressForUser(
      userId: _userId,
      level: level,
      xp: xp,
      streak: streak,
      totalAttempts: totalAttempts,
      accuracy: accuracy,
    );
    await OfflineStorageService.cacheProgressV1ForUser(
      userId: _userId,
      progress: data,
    );
    await _persistLastStreakDayToPrefs();
  }

  Future<void> persistLocalProgress() async {
    await _cacheProgressLocally();
  }

  ({int level, int xp, int streak, int totalAttempts, double accuracy})
  _buildPendingAwareSnapshot() {
    final attempts = totalAttempts + _pendingLocalProgress.pendingAnswerCount;
    final baseCorrect = (accuracy / 100.0 * totalAttempts).round();
    final correct = baseCorrect + _pendingLocalProgress.pendingCorrectAnswers;
    final previewAccuracy = attempts > 0 ? (correct / attempts) * 100.0 : 0.0;
    final totalXp = _baseTotalXp + _pendingLocalProgress.xpDelta;
    final levelXp = _levelXpFromTotalXp(totalXp);
    final previewStreak = displayStreak;
    return (
      level: levelXp['level']!,
      xp: levelXp['xp']!,
      streak: previewStreak,
      totalAttempts: attempts,
      accuracy: previewAccuracy,
    );
  }

  void _applyAuthoritativeRemoteProgress(Map<String, dynamic> remote) {
    totalAttempts =
        ((remote['totalAttempts'] ?? remote['totalAnswered']) as num?)
            ?.toInt() ??
        totalAttempts;
    accuracy = (remote['accuracy'] as num?)?.toDouble() ?? accuracy;
    streak =
        ((remote['streak'] ?? remote['dailyStreak']) as num?)?.toInt() ??
        streak;

    final remoteLevel = ((remote['level'] ?? remote['currentLevel']) as num?)
        ?.toInt();
    final remoteXp = ((remote['xp'] ?? remote['currentXp']) as num?)?.toInt();
    final remoteTotalXp =
        ((remote['totalXp'] ?? remote['totalExperience']) as num?)?.toInt();

    if (remoteLevel != null && remoteXp != null) {
      level = math.max(1, remoteLevel);
      xp = math.max(0, remoteXp);
      return;
    }

    if (remoteTotalXp != null) {
      final safeTotal = math.max(0, remoteTotalXp);
      final levelXp = _levelXpFromTotalXp(safeTotal);
      level = levelXp['level']!;
      xp = levelXp['xp']!;
      return;
    }

    // Last-resort fallback for legacy backend payloads without XP fields.
    _recalculateLevelAndXpFromAttempts();
  }

  int calculateXp(int attempts, double acc) {
    // Eksponencijalno nagrađivanje (osjećaj napretka)
    return ((acc / 100) * attempts * 12).toInt();
  }

  void _recalculateLevelAndXpFromAttempts() {
    final totalXp = calculateXp(totalAttempts, accuracy);
    level = 1;
    xp = totalXp;

    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      if (onLevelUp != null) onLevelUp!();
    }
  }

  // Topics list
  List<TopicProgress> topics = [];

  // Daily progress for heatmap
  Map<String, int> dailyProgress = {};

  Future<void> loadTopics({bool forceRefresh = false}) {
    if (!forceRefresh && _loadTopicsInFlight != null) {
      return _loadTopicsInFlight!;
    }

    final now = DateTime.now();
    final hasFreshData =
        _lastTopicsLoadedAt != null &&
        now.difference(_lastTopicsLoadedAt!) < _reloadDebounce &&
        topics.isNotEmpty;
    if (!forceRefresh && hasFreshData) {
      return Future.value();
    }

    final task = _loadTopicsInternal().whenComplete(() {
      _loadTopicsInFlight = null;
    });
    _loadTopicsInFlight = task;
    return task;
  }

  /// Loads the home/dashboard data bundle in a single deduplicated operation.
  /// This prevents multiple screens from kicking off overlapping startup calls.
  Future<void> loadHomeData({bool forceRefresh = false}) {
    if (!forceRefresh && _loadHomeDataInFlight != null) {
      return _loadHomeDataInFlight!;
    }

    final task = () async {
      await loadProgress(forceRefresh: forceRefresh);
      await loadTopics(forceRefresh: forceRefresh);
    }();

    _loadHomeDataInFlight = task.whenComplete(() {
      _loadHomeDataInFlight = null;
    });
    return _loadHomeDataInFlight!;
  }

  Future<void> _loadTopicsInternal() async {
    topicsUnavailable = false;

    if (!_isDemoMode) {
      try {
        final data = await api.getTopicsProgress();
        if (data != null) {
          topics = data.map((e) {
            final dto = TopicDto.fromJson(e);
            return TopicProgress(
              name: dto.name,
              requiredLevel: 1,
              unlocked: dto.unlocked,
              topicId: dto.id,
            );
          }).toList();
          _lastTopicsLoadedAt = DateTime.now();
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('Topics API failed: $e');
      }

      // Real users must not fall back to demo topics when the API fails.
      topicsUnavailable = true;
      _lastTopicsLoadedAt = DateTime.now();
      notifyListeners();
      return;
    }

    // Demo mode only: keep existing hardcoded demo topics fallback.
    topics = [
      TopicProgress(
        name: "Osnovne operacije",
        requiredLevel: 1,
        unlocked: true,
        topicId: 1,
      ),
      TopicProgress(
        name: "Razlomci",
        requiredLevel: 2,
        unlocked: level >= 2,
        topicId: 2,
      ),
      TopicProgress(
        name: "Geometrija",
        requiredLevel: 3,
        unlocked: level >= 3,
        topicId: 3,
      ),
      TopicProgress(
        name: "Algebra",
        requiredLevel: 4,
        unlocked: level >= 4,
        topicId: 4,
      ),
    ];

    _lastTopicsLoadedAt = DateTime.now();
    notifyListeners();
  }

  // Refresh after quiz completion
  Future<void> refreshAfterQuiz({BuildContext? context}) async {
    await loadProgress();
  }

  // LOCAL_AUTHORITY_TODO: local pending XP mutation; Daily Run chest XP should
  // come from backend claim + SERVER_REFRESHED progress.
  void addXP(int amount) {
    final event = PendingProgressEvent(
      id: _newPendingEventId('bonusXp'),
      type: PendingProgressEventType.bonusXp,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      xp: amount,
    );
    _pendingLocalProgress = _pendingLocalProgress.add(event);
    unawaited(_cachePendingEventsLocally());
    notifyListeners();
  }

  Future<void> applyPracticeRoundReward({
    required int xpEarned,
    DateTime? now,
  }) async {
    // LOCAL_AUTHORITY_TODO: practice reward XP is queued locally until sync.
    final day = _dateOnly(now ?? DateTime.now());
    final event = PendingProgressEvent(
      id: _newPendingEventId('practiceReward'),
      type: PendingProgressEventType.practiceReward,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      xp: xpEarned > 0 ? xpEarned : 0,
      dayKey: _dayKey(day),
    );
    _pendingLocalProgress = _pendingLocalProgress.add(event);
    _pendingStreakRollEvent = _pendingLocalProgress.latestStreakRoll;
    await _cachePendingEventsLocally();
    notifyListeners();
  }

  // Penalize XP for using hints
  void penalizeXp(int amount) {
    final event = PendingProgressEvent(
      id: _newPendingEventId('bonusXp'),
      type: PendingProgressEventType.bonusXp,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      xp: -amount.abs(),
    );
    _pendingLocalProgress = _pendingLocalProgress.add(event);
    unawaited(_cachePendingEventsLocally());
    notifyListeners();
  }

  String getBadgeName() {
    if (accuracy >= 90) return "Math Prodigy 🧠";
    if (accuracy >= 70) return "Quick Thinker ⚡";
    if (accuracy >= 50) return "Learner 📘";
    return "Beginner 🌱";
  }

  String get _lastStreakDayKey =>
      UserScopedStorage.scopedKey(_userId, 'progress', 'last_streak_day_ms');
}

// Topic progress model
class TopicProgress {
  final String name;
  final int requiredLevel;
  final bool unlocked;
  final int topicId; // Add missing topicId

  TopicProgress({
    required this.name,
    required this.requiredLevel,
    required this.unlocked,
    required this.topicId,
  });

  factory TopicProgress.fromJson(Map<String, dynamic> json) {
    return TopicProgress(
      name: json['name'],
      requiredLevel: json['requiredLevel'],
      unlocked: json['unlocked'],
      topicId: json['topicId'] ?? 1, // Default to 1 if missing
    );
  }
}
