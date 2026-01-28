import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/topic_dto.dart';
import '../services/offline_storage_service.dart';

class ProgressProvider extends ChangeNotifier {
  final api = ApiService();

  String? token;

  int level = 1;
  int xp = 0;
  int xpToNextLevel = 100;

  int streak = 0;
  int totalAttempts = 0;
  double accuracy = 0;

  VoidCallback? onLevelUp; // callback za animaciju

  Future<void> loadProgress() async {
    try {
      // Skip API call if using demo token (backend not ready)
      if (token?.startsWith('demo_token') != true) {
        final data = await api.get("/api/progress/overview", token);
        if (data != null) {
          totalAttempts = data["totalAttempts"] ?? 0;
          accuracy = (data["accuracy"] as num?)?.toDouble() ?? 0.0;
          streak = data["streak"] ?? 0;

          // XP se generiše iz performansa
          xp = calculateXp(totalAttempts, accuracy);

          // PROVERI LEVEL UP
          while (xp >= xpToNextLevel) {
            xp -= xpToNextLevel;
            level++;

            // TRIGGER LEVEL UP ANIMACIJE
            if (onLevelUp != null) onLevelUp!();
          }

          // Cache progress data for offline use
          await OfflineStorageService.cacheUserProgress(
            level: level,
            xp: xp,
            streak: streak,
            totalAttempts: totalAttempts,
            accuracy: accuracy,
          );

          notifyListeners();
          return;
        }
      }
    } catch (e) {
      // API failed, try loading from cache
      debugPrint('Progress API failed: $e');
      final cached = await OfflineStorageService.getCachedUserProgress();
      if (cached != null) {
        level = cached['level'];
        xp = cached['xp'];
        streak = cached['streak'];
        totalAttempts = cached['total_attempts'];
        accuracy = cached['accuracy'];
        notifyListeners();
        return;
      }
    }

    // Fallback demo data (when using demo token, API fails, and no cache)
    totalAttempts = 15;
    accuracy = 75.0;
    streak = 3;
    xp = calculateXp(totalAttempts, accuracy);

    notifyListeners();
  }

  int calculateXp(int attempts, double acc) {
    // Eksponencijalno nagrađivanje (osjećaj napretka)
    return ((acc / 100) * attempts * 12).toInt();
  }

  // Topics list
  List<TopicProgress> topics = [];

  // Daily progress for heatmap
  Map<String, int> dailyProgress = {};

  Future<void> loadTopics() async {
    try {
      // Skip API call if using demo token (backend not ready)
      if (token?.startsWith('demo_token') != true) {
        final data = await api.get("/api/progress/topics", token);
        if (data != null) {
          topics = (data as List).map((e) {
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
