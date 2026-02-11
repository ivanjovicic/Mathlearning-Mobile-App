import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import '../models/topic_dto.dart';
import '../services/offline_storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  final api = ApiService();
  final ProgressService _progressService = ProgressService.instance;

  String? token;

  int level = 1;
  int xp = 0;
  int xpToNextLevel = 100;

  int streak = 0;
  int totalAttempts = 0;
  double accuracy = 0;

  VoidCallback? onLevelUp; // callback za animaciju

  // ─── Optimistic update: apply XP / streak instantly ───

  /// Called by QuizProvider right after answering a question.
  /// Updates XP & streak immediately (works offline too).
  void applyAnswerResult({required bool isCorrect, int xpForQuestion = 10}) {
    totalAttempts++;

    if (isCorrect) {
      xp += xpForQuestion;
      streak++;

      // Level-up check
      while (xp >= xpToNextLevel) {
        xp -= xpToNextLevel;
        level++;
        if (onLevelUp != null) onLevelUp!();
      }
    } else {
      // Wrong answer doesn't break streak, but doesn't increase it
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

  Future<void> loadProgress() async {
    // 1) Try from cache first (instant UI)
    var cached = await OfflineStorageService.getCachedUserProgress();
    cached ??= await OfflineStorageService.loadCachedProgressV1();
    if (cached != null) {
      _applyFromCache(cached, notify: false);
    }

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
          final remoteAttempts = data["totalAttempts"] ?? 0;
          final remoteAccuracy = (data["accuracy"] as num?)?.toDouble() ?? 0.0;
          final remoteStreak = data["streak"] ?? 0;

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
        final remoteAttempts = remote['totalAttempts'] ?? totalAttempts;
        final remoteAccuracy =
            (remote['accuracy'] as num?)?.toDouble() ?? accuracy;
        final remoteStreak = remote['streak'] ?? streak;
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
    if (notify) notifyListeners();
  }

  Future<void> _cacheProgressLocally() async {
    final data = {
      'level': level,
      'xp': xp,
      'streak': streak,
      'total_attempts': totalAttempts,
      'accuracy': accuracy,
    };

    await OfflineStorageService.cacheUserProgress(
      level: level,
      xp: xp,
      streak: streak,
      totalAttempts: totalAttempts,
      accuracy: accuracy,
    );
    await OfflineStorageService.cacheProgressV1(data);
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

  Future<void> loadTopics() async {
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
