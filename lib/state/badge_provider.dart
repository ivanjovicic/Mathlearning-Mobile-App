import 'package:flutter/material.dart';
import '../state/progress_provider.dart';

class AppBadge {
  final String name;
  final String icon;
  final bool unlocked;
  final double progress; // 0.0 - 1.0

  AppBadge({
    required this.name,
    required this.icon,
    required this.unlocked,
    required this.progress,
  });
}

class BadgeProvider extends ChangeNotifier {
  final ProgressProvider progress;

  BadgeProvider(this.progress);

  List<AppBadge> get badges {
    double acc = progress.accuracy;
    int streak = progress.streak;
    int xp = progress.xp;

    return [
      AppBadge(
        name: "Tacnost 50%",
        icon: "📘",
        unlocked: acc >= 50,
        progress: (acc / 50).clamp(0, 1),
      ),
      AppBadge(
        name: "Tacnost 70%",
        icon: "⚡",
        unlocked: acc >= 70,
        progress: (acc / 70).clamp(0, 1),
      ),
      AppBadge(
        name: "Tacnost 90%",
        icon: "🧠",
        unlocked: acc >= 90,
        progress: (acc / 90).clamp(0, 1),
      ),
      AppBadge(
        name: "Niz 3 dana",
        icon: "🔥",
        unlocked: streak >= 3,
        progress: (streak / 3).clamp(0, 1),
      ),
      AppBadge(
        name: "Niz 7 dana",
        icon: "🌋",
        unlocked: streak >= 7,
        progress: (streak / 7).clamp(0, 1),
      ),
      AppBadge(
        name: "100 XP osvojeno",
        icon: "⭐",
        unlocked: xp >= 100,
        progress: (xp / 100).clamp(0, 1),
      ),
      AppBadge(
        name: "500 XP osvojeno",
        icon: "💎",
        unlocked: xp >= 500,
        progress: (xp / 500).clamp(0, 1),
      ),
    ];
  }
}
