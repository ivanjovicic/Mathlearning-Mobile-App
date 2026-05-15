import 'package:flutter/foundation.dart';

enum DailyReturnModifierType {
  doubleFragmentDay,
  bonusXpRun,
  streakBonusActive,
  featuredCosmeticBoost,
  finalDayBonus,
}

extension DailyReturnModifierTypeX on DailyReturnModifierType {
  String get label => switch (this) {
    DailyReturnModifierType.doubleFragmentDay => '2x fragment boost active',
    DailyReturnModifierType.bonusXpRun => 'Bonus XP run',
    DailyReturnModifierType.streakBonusActive => 'Streak bonus active',
    DailyReturnModifierType.featuredCosmeticBoost => 'Featured cosmetic boost',
    DailyReturnModifierType.finalDayBonus => 'Final day bonus!',
  };

  String get shortLabel => switch (this) {
    DailyReturnModifierType.doubleFragmentDay => '2x fragments',
    DailyReturnModifierType.bonusXpRun => 'Bonus XP',
    DailyReturnModifierType.streakBonusActive => 'Streak boost',
    DailyReturnModifierType.featuredCosmeticBoost => 'Featured boost',
    DailyReturnModifierType.finalDayBonus => 'Final day',
  };

  String get description => switch (this) {
    DailyReturnModifierType.doubleFragmentDay =>
      'Daily Run chests grant one extra copy of the fragment they drop.',
    DailyReturnModifierType.bonusXpRun =>
      'Today\'s Daily Run chest grants extra XP.',
    DailyReturnModifierType.streakBonusActive =>
      'Your current streak multiplier is a little stronger today.',
    DailyReturnModifierType.featuredCosmeticBoost =>
      'Active weekly cosmetics can appear in Daily Run chests.',
    DailyReturnModifierType.finalDayBonus =>
      'The weekly goal resets tomorrow, so today has one honest final-day boost.',
  };

  int get priority => switch (this) {
    DailyReturnModifierType.finalDayBonus => 0,
    DailyReturnModifierType.doubleFragmentDay => 1,
    DailyReturnModifierType.featuredCosmeticBoost => 2,
    DailyReturnModifierType.streakBonusActive => 3,
    DailyReturnModifierType.bonusXpRun => 4,
  };
}

@immutable
class DailyReturnModifier {
  const DailyReturnModifier({required this.type});

  final DailyReturnModifierType type;

  String get label => type.label;
  String get shortLabel => type.shortLabel;
  String get description => type.description;
  int get priority => type.priority;

  Map<String, dynamic> toJson() => {'type': type.name};

  factory DailyReturnModifier.fromJson(Map<String, dynamic> json) {
    final raw = json['type']?.toString();
    return DailyReturnModifier(
      type: DailyReturnModifierType.values.firstWhere(
        (entry) => entry.name == raw,
        orElse: () => DailyReturnModifierType.bonusXpRun,
      ),
    );
  }
}

@immutable
class DailyReturnComebackReward {
  const DailyReturnComebackReward({
    required this.missedDays,
    required this.recoveryRunsRequired,
    required this.recoveryRunsCompleted,
    this.welcomeBackChestAvailable = true,
  });

  final int missedDays;
  final bool welcomeBackChestAvailable;
  final int recoveryRunsRequired;
  final int recoveryRunsCompleted;

  bool get recoveryComplete => recoveryRunsCompleted >= recoveryRunsRequired;

  String get title => 'Welcome-back chest';

  String get missionLabel => recoveryComplete
      ? 'Recovery mission complete'
      : 'Recovery mission: complete 1 Daily Run';

  Map<String, dynamic> toJson() => {
    'missedDays': missedDays,
    'welcomeBackChestAvailable': welcomeBackChestAvailable,
    'recoveryRunsRequired': recoveryRunsRequired,
    'recoveryRunsCompleted': recoveryRunsCompleted,
  };

  factory DailyReturnComebackReward.fromJson(Map<String, dynamic> json) {
    final welcomeBackRaw =
        json['welcomeBackChestAvailable'] ??
        json['welcome_back_chest_available'];
    return DailyReturnComebackReward(
      missedDays: _asInt(json['missedDays'] ?? json['missed_days']) ?? 0,
      welcomeBackChestAvailable: welcomeBackRaw is bool
          ? welcomeBackRaw
          : welcomeBackRaw?.toString().toLowerCase() == 'true',
      recoveryRunsRequired:
          _asInt(
            json['recoveryRunsRequired'] ?? json['recovery_runs_required'],
          ) ??
          1,
      recoveryRunsCompleted:
          _asInt(
            json['recoveryRunsCompleted'] ?? json['recovery_runs_completed'],
          ) ??
          0,
    );
  }
}

@immutable
class DailyReturnWeeklyGoal {
  const DailyReturnWeeklyGoal({
    required this.id,
    required this.title,
    required this.progress,
    required this.target,
  });

  final String id;
  final String title;
  final int progress;
  final int target;

  bool get isComplete => progress >= target;

  double get progressValue {
    if (target <= 0) return 0;
    return (progress / target).clamp(0.0, 1.0);
  }

  String get compactLabel => '$progress/$target';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'progress': progress,
    'target': target,
  };

  factory DailyReturnWeeklyGoal.fromJson(Map<String, dynamic> json) {
    return DailyReturnWeeklyGoal(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      progress: _asInt(json['progress']) ?? 0,
      target: _asInt(json['target']) ?? 1,
    );
  }
}

@immutable
class StreakMilestone {
  const StreakMilestone({
    required this.days,
    required this.label,
    required this.rewardLabel,
  });

  final int days;
  final String label;
  final String rewardLabel;

  Map<String, dynamic> toJson() => {
    'days': days,
    'label': label,
    'rewardLabel': rewardLabel,
  };
}

@immutable
class DailyReturnState {
  const DailyReturnState({
    required this.userId,
    required this.dateKey,
    required this.currentStreak,
    required this.practicedToday,
    required this.streakFreezeCount,
    required this.streakMultiplier,
    required this.chestQualityLabel,
    required this.weeklyGoals,
    required this.modifiers,
    required this.reachedMilestones,
    this.lastDailyRunDate,
    this.missedDays = 0,
    this.streakAtRisk = false,
    this.streakProtectedToday = false,
    this.streakBroken = false,
    this.comebackReward,
  });

  final String userId;
  final String dateKey;
  final DateTime? lastDailyRunDate;
  final int currentStreak;
  final bool practicedToday;
  final int streakFreezeCount;
  final double streakMultiplier;
  final int missedDays;
  final bool streakAtRisk;
  final bool streakProtectedToday;
  final bool streakBroken;
  final String chestQualityLabel;
  final DailyReturnComebackReward? comebackReward;
  final List<DailyReturnWeeklyGoal> weeklyGoals;
  final List<DailyReturnModifier> modifiers;
  final List<StreakMilestone> reachedMilestones;

  bool get hasComebackReward =>
      comebackReward?.welcomeBackChestAvailable == true;

  bool get hasDoubleFragmentDay => modifiers.any(
    (entry) => entry.type == DailyReturnModifierType.doubleFragmentDay,
  );

  bool get hasBonusXp => modifiers.any(
    (entry) =>
        entry.type == DailyReturnModifierType.bonusXpRun ||
        entry.type == DailyReturnModifierType.finalDayBonus,
  );

  bool get hasStreakBonus => modifiers.any(
    (entry) => entry.type == DailyReturnModifierType.streakBonusActive,
  );

  DailyReturnWeeklyGoal? get dailyRunsGoal {
    for (final goal in weeklyGoals) {
      if (goal.id == 'weekly_daily_runs') return goal;
    }
    return weeklyGoals.isEmpty ? null : weeklyGoals.first;
  }

  String get primaryMessage {
    if (streakProtectedToday) {
      return 'Streak freeze protected you';
    }
    if (streakAtRisk) {
      return '1 run saves your streak';
    }
    if (hasComebackReward) {
      return 'Welcome back chest waiting';
    }
    DailyReturnModifier? urgent;
    for (final entry in modifiers) {
      if (entry.type == DailyReturnModifierType.finalDayBonus ||
          entry.type == DailyReturnModifierType.doubleFragmentDay) {
        urgent = entry;
        break;
      }
    }
    if (urgent != null) return urgent.label;
    return '${streakMultiplier.toStringAsFixed(2)}x streak multiplier';
  }

  String get supportiveMessage {
    if (streakAtRisk) {
      return 'No timers, no tricks. Complete one Daily Run today to keep it.';
    }
    if (hasComebackReward) {
      final missed = comebackReward?.missedDays ?? missedDays;
      return 'You missed $missed day${missed == 1 ? '' : 's'}. Complete a run to recover momentum.';
    }
    final goal = dailyRunsGoal;
    if (goal != null && !goal.isComplete) {
      final left = (goal.target - goal.progress).clamp(0, goal.target).toInt();
      return '$left Daily Run${left == 1 ? '' : 's'} left for this week\'s goal.';
    }
    return 'Today\'s bonuses are based on your real streak and calendar.';
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'dateKey': dateKey,
    'lastDailyRunDate': lastDailyRunDate?.toIso8601String(),
    'currentStreak': currentStreak,
    'practicedToday': practicedToday,
    'streakFreezeCount': streakFreezeCount,
    'streakMultiplier': streakMultiplier,
    'missedDays': missedDays,
    'streakAtRisk': streakAtRisk,
    'streakProtectedToday': streakProtectedToday,
    'streakBroken': streakBroken,
    'chestQualityLabel': chestQualityLabel,
    'comebackReward': comebackReward?.toJson(),
    'weeklyGoals': weeklyGoals.map((entry) => entry.toJson()).toList(),
    'modifiers': modifiers.map((entry) => entry.toJson()).toList(),
    'reachedMilestones': reachedMilestones
        .map((entry) => entry.toJson())
        .toList(),
  };
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
