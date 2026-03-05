import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import '../models/topic_dto.dart';
import '../services/offline_storage_service.dart';
import 'streak_freeze_provider.dart';
import 'dart:math' as math;

class ProgressProvider extends ChangeNotifier {
  final api = ApiService();
  final ProgressService _progressService = ProgressService.instance;
  static const Duration _reloadDebounce = Duration(seconds: 4);
  static const String _keyLastStreakDayMs = 'progress_last_streak_day_ms_v1';

  StreakFreezeProvider? _streakFreeze;
  DateTime? _lastStreakDay;
  ({int freezesUsed, bool streakBroken})? _pendingStreakRollEvent;

  String? token;

  int level = 1;
  int xp = 0;
  int xpToNextLevel = 100;

  int streak = 0;
  int totalAttempts = 0;
  double accuracy = 0;

  VoidCallback? onLevelUp; // callback za animaciju
  Future<void>? _loadProgressInFlight;
  Future<void>? _loadTopicsInFlight;
  DateTime? _lastProgressLoadedAt;
  DateTime? _lastTopicsLoadedAt;

  void updateStreakFreezeProvider(StreakFreezeProvider provider) {
    _streakFreeze = provider;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool get isStreakDoneToday {
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

  Future<void> _loadLastStreakDayFromPrefs() async {
    if (_lastStreakDay != null) return;
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_keyLastStreakDayMs);
    if (ms == null) return;
    _lastStreakDay = _dateOnly(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  Future<void> _persistLastStreakDayToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = _lastStreakDay?.millisecondsSinceEpoch;
    if (ms == null) {
      await prefs.remove(_keyLastStreakDayMs);
      return;
    }
    await prefs.setInt(_keyLastStreakDayMs, ms);
  }

  /// If the user missed one or more days, attempt to consume streak freezes.
  /// Returns how many freezes were used and whether the streak was broken.
  Future<({int freezesUsed, bool streakBroken})> rollDailyStreakIfNeeded({
    DateTime? now,
  }) async {
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
    if (remainingMissedDays > 0) {
      // Not enough freezes to cover the gap -> streak breaks.
      streak = 0;
      _lastStreakDay = null;
    }

    _pendingStreakRollEvent = (
      freezesUsed: freezesUsed,
      streakBroken: remainingMissedDays > 0,
    );

    await _cacheProgressLocally();
    notifyListeners();
    return (freezesUsed: freezesUsed, streakBroken: remainingMissedDays > 0);
  }

  // ─── Optimistic update: apply XP / streak instantly ───

  /// Called by QuizProvider right after answering a question.
  /// Updates XP & streak immediately (works offline too).
  void applyAnswerResult({required bool isCorrect, int xpForQuestion = 10}) {
    totalAttempts++;

    if (isCorrect) {
      xp += xpForQuestion;

      // Level-up check
      while (xp >= xpToNextLevel) {
        xp -= xpToNextLevel;
        level++;
        if (onLevelUp != null) onLevelUp!();
      }
    } else {
      // Wrong answer doesn't break streak, but doesn't increase it
    }

    // Daily streak: count at most once per calendar day (practice == any attempt).
    final today = _dateOnly(DateTime.now());
    final last = _lastStreakDay;
    if (last == null) {
      // If we have a streak number but no date, don't rewrite history.
      if (streak <= 0) streak = 1;
      _lastStreakDay = today;
    } else {
      final diff = today.difference(_dateOnly(last)).inDays;
      if (diff == 1) {
        streak = (streak < 1 ? 1 : streak) + 1;
        _lastStreakDay = today;
      } else if (diff > 1) {
        // If rollDailyStreakIfNeeded wasn't called yet, consider the streak broken.
        streak = 1;
        _lastStreakDay = today;
      }
    }

    // Recalculate accuracy optimistically
    // (rough: can't know exact server accuracy, but keep local consistent)
    if (totalAttempts > 0) {
      // We track correct count implicitly: accuracy * oldAttempts + (1 or 0)
      final oldCorrectCount = ((accuracy / 100.0) * (totalAttempts - 1))
          .round();
      final newCorrectCount = oldCorrectCount + (isCorrect ? 1 : 0);
      accuracy = (newCorrectCount / totalAttempts) * 100.0;
    }

    _cacheProgressLocally();
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

  Future<void> _loadProgressInternal() async {
    // 1) Try from cache first (instant UI)
    var cached = await OfflineStorageService.getCachedUserProgress();
    cached ??= await OfflineStorageService.loadCachedProgressV1();
    if (cached != null) {
      _applyFromCache(cached, notify: false);
    }

    // Ensure meta (like last streak day) is present even when SQLite cache is used.
    await _loadLastStreakDayFromPrefs();

    final localAttempts = totalAttempts;
    final localAccuracy = accuracy;
    final localStreak = streak;
    final localXp = xp;
    final localLevel = level;

    // 2) Try from server to reconcile
    try {
      if (token?.startsWith('demo_') != true) {
        final data = await api.get("/api/progress/overview", token);
        if (data != null) {
          final remoteAttempts =
              ((data["totalAttempts"] ?? data["totalAnswered"]) as num?)
                  ?.toInt() ??
              0;
          final remoteAccuracy = (data["accuracy"] as num?)?.toDouble() ?? 0.0;
          final remoteStreak =
              ((data["streak"] ?? data["dailyStreak"]) as num?)?.toInt() ?? 0;

          final remoteIsNewer =
              remoteAttempts > localAttempts ||
              (remoteAttempts == localAttempts &&
                  remoteAccuracy >= localAccuracy);

          if (remoteIsNewer) {
            totalAttempts = remoteAttempts;
            accuracy = remoteAccuracy;
            streak = remoteStreak;
            _recalculateLevelAndXpFromAttempts();
          } else {
            totalAttempts = localAttempts;
            accuracy = localAccuracy;
            streak = localStreak;
            xp = localXp;
            level = localLevel;
          }

          await _cacheProgressLocally();
          await rollDailyStreakIfNeeded();
          _lastProgressLoadedAt = DateTime.now();
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Progress API failed: $e');
      // Already loaded from cache above, so UI still has data
      if (cached != null) {
        notifyListeners();
        return;
      }
    }

    // 3) Fallback demo data (when using demo token, API fails, and no cache)
    if (cached == null) {
      totalAttempts = 15;
      accuracy = 75.0;
      streak = 3;
      xp = calculateXp(totalAttempts, accuracy);
    }

    await rollDailyStreakIfNeeded();
    _lastProgressLoadedAt = DateTime.now();
    notifyListeners();
  }

  // ─── Sync local progress with server (reconcile after offline) ───

  /// Push local state to server, then pull authoritative copy back.
  Future<void> syncWithServer() async {
    final localAttempts = totalAttempts;
    final localAccuracy = accuracy;
    final localStreak = streak;
    final localXp = xp;
    final localLevel = level;

    final localMap = {
      'level': level,
      'xp': xp,
      'streak': streak,
      'totalAttempts': totalAttempts,
      'accuracy': accuracy,
    };

    try {
      await _progressService.pushProgress(localMap);

      // Pull authoritative state from server
      final remote = await _progressService.fetchProgress();
      if (remote != null) {
        final remoteAttempts =
            ((remote['totalAttempts'] ?? remote['totalAnswered']) as num?)
                ?.toInt() ??
            totalAttempts;
        final remoteAccuracy =
            (remote['accuracy'] as num?)?.toDouble() ?? accuracy;
        final remoteStreak =
            ((remote['streak'] ?? remote['dailyStreak']) as num?)?.toInt() ??
            streak;
        // Do not regress local quiz progress with stale remote snapshot.
        final remoteIsNewer =
            remoteAttempts > localAttempts ||
            (remoteAttempts == localAttempts &&
                remoteAccuracy >= localAccuracy);
        if (remoteIsNewer) {
          totalAttempts = remoteAttempts;
          accuracy = remoteAccuracy;
          streak = remoteStreak;
          _recalculateLevelAndXpFromAttempts();
        } else {
          totalAttempts = localAttempts;
          accuracy = localAccuracy;
          streak = localStreak;
          xp = localXp;
          level = localLevel;
        }

        await _cacheProgressLocally();
        notifyListeners();
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
      _lastStreakDay = _dateOnly(DateTime.fromMillisecondsSinceEpoch(lastStreakMs));
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

    await OfflineStorageService.cacheUserProgress(
      level: level,
      xp: xp,
      streak: streak,
      totalAttempts: totalAttempts,
      accuracy: accuracy,
    );
    await OfflineStorageService.cacheProgressV1(data);
    await _persistLastStreakDayToPrefs();
  }

  Future<void> persistLocalProgress() async {
    await _cacheProgressLocally();
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

  Future<void> _loadTopicsInternal() async {
    try {
      // Skip API call if using demo token (backend not ready)
      if (token?.startsWith('demo_') != true) {
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
      }
    } catch (e) {
      // API failed, use demo topics
      debugPrint('Topics API failed: $e');
    }

    // Fallback demo topics (when using demo token or API fails)
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

  // Test method to manually add XP
  void addXP(int amount) {
    xp += amount;

    // Check for level-up
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;

      // TRIGGER LEVEL UP ANIMACIJE
      if (onLevelUp != null) onLevelUp!();
    }

    notifyListeners();
  }

  // Penalize XP for using hints
  void penalizeXp(int amount) {
    xp -= amount;

    // Prevent negative XP and level degradation
    if (xp < 0) {
      if (level > 1) {
        // Go down a level
        level--;
        xp += xpToNextLevel;
        // If still negative, set to 0
        if (xp < 0) xp = 0;
      } else {
        // Minimum level 1, XP can't go below 0
        xp = 0;
      }
    }

    notifyListeners();
  }

  String getBadgeName() {
    if (accuracy >= 90) return "Math Prodigy 🧠";
    if (accuracy >= 70) return "Quick Thinker ⚡";
    if (accuracy >= 50) return "Learner 📘";
    return "Beginner 🌱";
  }
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
