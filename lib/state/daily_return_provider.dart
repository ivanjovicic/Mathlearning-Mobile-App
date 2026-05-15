import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/daily_return.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/streak_freeze_provider.dart';
import 'package:mathlearning/state/weekly_featured_provider.dart';

class DailyReturnProvider extends ChangeNotifier {
  static const _storagePrefix = 'daily_return.state.v1.';
  static const _weeklyRunsGoal = 5;

  String _userId = 'local';
  bool _loaded = false;
  bool _loading = false;
  DateTime? _lastDailyRunDate;
  String? _weekId;
  int _weeklyDailyRuns = 0;
  String? _welcomeBackClaimedDateKey;
  String? _recoveryCompletedDateKey;
  String? _freezeProtectedDateKey;
  int _pendingComebackMissedDays = 0;
  DailyReturnState? _state;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;
  DailyReturnState? get state => _state;

  double get streakMultiplier => _state?.streakMultiplier ?? 1.0;
  bool get hasDoubleFragmentDay => _state?.hasDoubleFragmentDay ?? false;

  void configureUser(String? userId, {bool autoLoad = true}) {
    final safeUserId = _safeUserId(userId);
    if (_userId == safeUserId && _loaded) return;
    _userId = safeUserId;
    _loaded = false;
    _loading = true;
    notifyListeners();
    if (autoLoad) {
      unawaited(load(userId: safeUserId));
    } else {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> load({
    String? userId,
    DateTime? now,
    ProgressProvider? progress,
    StreakFreezeProvider? streakFreeze,
    WeeklyFeaturedProvider? weeklyFeatured,
  }) async {
    final safeUserId = _safeUserId(userId ?? _userId);
    _userId = safeUserId;
    _loading = true;
    notifyListeners();
    await _loadPersisted(safeUserId, now: now);
    _loading = false;
    _loaded = true;
    rebuild(
      now: now,
      progress: progress,
      streakFreeze: streakFreeze,
      weeklyFeatured: weeklyFeatured,
      notify: false,
    );
    notifyListeners();
  }

  void rebuild({
    DateTime? now,
    ProgressProvider? progress,
    StreakFreezeProvider? streakFreeze,
    WeeklyFeaturedProvider? weeklyFeatured,
    bool notify = true,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final dateKey = _dateKey(today);
    final weekId = _weekKey(today);
    if (_weekId != null && _weekId != weekId) {
      _weekId = weekId;
      _weeklyDailyRuns = 0;
    } else {
      _weekId ??= weekId;
    }

    final lastActivity = _lastDailyRunDate ?? progress?.lastStreakDay;
    final practicedToday =
        progress?.isStreakDoneToday == true ||
        (lastActivity != null && _dateOnly(lastActivity) == today);
    final missedDays = _missedDaysSince(lastActivity, today);
    final rollEvent = progress?.takeStreakRollEvent();
    if (rollEvent != null) {
      if (rollEvent.freezesUsed > 0) {
        _freezeProtectedDateKey = dateKey;
        unawaited(_persist());
      }
      if (rollEvent.streakBroken && _pendingComebackMissedDays == 0) {
        _pendingComebackMissedDays = math.max(1, missedDays);
        unawaited(_persist());
      }
    }
    final atRisk =
        (progress?.streak ?? 0) > 0 && !practicedToday && missedDays == 0;
    final hasPendingComeback =
        _pendingComebackMissedDays > 0 && _welcomeBackClaimedDateKey != dateKey;
    final hasFreshComeback =
        missedDays > 0 && _welcomeBackClaimedDateKey != dateKey;
    final comebackMissedDays = hasPendingComeback
        ? _pendingComebackMissedDays
        : missedDays;

    final modifiers = _modifiersFor(
      today,
      hasWeeklyFeatured: weeklyFeatured?.activeSet != null,
    );
    final streak = progress?.streak ?? 0;
    final multiplier = _streakMultiplierFor(streak, modifiers);
    final freezeCount = streakFreeze?.count ?? 0;
    final chestQuality = _chestQualityFor(streak);
    final protectedToday =
        _freezeProtectedDateKey == dateKey ||
        (_recoveryCompletedDateKey == dateKey && freezeCount >= 0);
    final weeklyGoals = [
      DailyReturnWeeklyGoal(
        id: 'weekly_daily_runs',
        title: '5 Daily Runs',
        progress: _weeklyDailyRuns.clamp(0, _weeklyRunsGoal).toInt(),
        target: _weeklyRunsGoal,
      ),
      DailyReturnWeeklyGoal(
        id: 'weekly_streak',
        title: 'Streak milestone',
        progress: streak.clamp(0, 7).toInt(),
        target: 7,
      ),
    ];

    _state = DailyReturnState(
      userId: _userId,
      dateKey: dateKey,
      lastDailyRunDate: lastActivity,
      currentStreak: streak,
      practicedToday: practicedToday,
      streakFreezeCount: freezeCount,
      streakMultiplier: multiplier,
      missedDays: comebackMissedDays,
      streakAtRisk: atRisk,
      streakProtectedToday: protectedToday,
      streakBroken: missedDays > 0 && streak == 0,
      chestQualityLabel: chestQuality,
      comebackReward: (hasFreshComeback || hasPendingComeback)
          ? DailyReturnComebackReward(
              missedDays: comebackMissedDays,
              recoveryRunsRequired: 1,
              recoveryRunsCompleted: _recoveryCompletedDateKey == dateKey
                  ? 1
                  : 0,
            )
          : null,
      weeklyGoals: weeklyGoals,
      modifiers: modifiers,
      reachedMilestones: _milestonesFor(streak),
    );

    if (notify) notifyListeners();
  }

  Future<void> recordDailyRunCompleted({
    DateTime? now,
    ProgressProvider? progress,
    StreakFreezeProvider? streakFreeze,
    WeeklyFeaturedProvider? weeklyFeatured,
  }) async {
    if (!_loaded) {
      await _loadPersisted(_userId, now: now);
      _loaded = true;
    }
    final today = _dateOnly(now ?? DateTime.now());
    final dateKey = _dateKey(today);
    final weekId = _weekKey(today);
    if (_weekId != weekId) {
      _weekId = weekId;
      _weeklyDailyRuns = 0;
    }

    final previousActivity = _lastDailyRunDate ?? progress?.lastStreakDay;
    final missedBeforeRun = _missedDaysSince(previousActivity, today);
    if (missedBeforeRun > 0 && _welcomeBackClaimedDateKey != dateKey) {
      _pendingComebackMissedDays = missedBeforeRun;
      _recoveryCompletedDateKey = dateKey;
    }

    if (_lastDailyRunDate == null || _dateOnly(_lastDailyRunDate!) != today) {
      _weeklyDailyRuns = (_weeklyDailyRuns + 1).clamp(0, 99).toInt();
    }
    _lastDailyRunDate = today;

    await _persist();
    rebuild(
      now: today,
      progress: progress,
      streakFreeze: streakFreeze,
      weeklyFeatured: weeklyFeatured,
    );
  }

  DailyChestReward applyRewardModifiers(
    DailyChestReward reward, {
    DateTime? now,
  }) {
    final state = _state;
    if (state == null) return reward;
    final todayKey = _dateKey(_dateOnly(now ?? DateTime.now()));
    final labels = <String>{...reward.modifierLabels};
    var xpMultiplier = state.streakMultiplier;
    var fragmentCopies = reward.fragmentCopies;
    var coins = reward.coins;
    var isComebackChest = reward.isComebackChest;

    if (state.hasBonusXp) {
      xpMultiplier += 0.15;
      labels.add('Bonus XP run');
    }
    if (state.hasDoubleFragmentDay) {
      fragmentCopies = math.max(fragmentCopies, 2);
      labels.add('2x fragment boost active');
    }
    if (state.modifiers.any(
      (entry) => entry.type == DailyReturnModifierType.featuredCosmeticBoost,
    )) {
      labels.add('Featured cosmetic boost');
    }

    final comeback = state.comebackReward;
    if (comeback?.welcomeBackChestAvailable == true &&
        _welcomeBackClaimedDateKey != todayKey) {
      isComebackChest = true;
      xpMultiplier += 0.10;
      coins += 5;
      labels.add('Welcome-back chest');
    }

    return reward.copyWith(
      xp: math.max(1, (reward.xp * xpMultiplier).round()),
      coins: coins,
      fragmentCopies: fragmentCopies.clamp(1, 3).toInt(),
      modifierLabels: labels.toList(growable: false),
      chestQualityLabel: state.chestQualityLabel,
      isComebackChest: isComebackChest,
    );
  }

  Future<void> markChestOpened({
    DateTime? now,
    bool wasComebackChest = false,
    ProgressProvider? progress,
    StreakFreezeProvider? streakFreeze,
    WeeklyFeaturedProvider? weeklyFeatured,
  }) async {
    if (!wasComebackChest) return;
    final today = _dateOnly(now ?? DateTime.now());
    _welcomeBackClaimedDateKey = _dateKey(today);
    _pendingComebackMissedDays = 0;
    await _persist();
    rebuild(
      now: today,
      progress: progress,
      streakFreeze: streakFreeze,
      weeklyFeatured: weeklyFeatured,
    );
  }

  List<DailyReturnModifier> _modifiersFor(
    DateTime today, {
    required bool hasWeeklyFeatured,
  }) {
    final modifiers = <DailyReturnModifier>[];
    final rotation = (_daysSinceEpoch(today) + _stableHash(_userId)) % 3;
    final dailyType = switch (rotation) {
      0 => DailyReturnModifierType.doubleFragmentDay,
      1 => DailyReturnModifierType.bonusXpRun,
      _ => DailyReturnModifierType.streakBonusActive,
    };
    modifiers.add(DailyReturnModifier(type: dailyType));
    if (hasWeeklyFeatured) {
      modifiers.add(
        const DailyReturnModifier(
          type: DailyReturnModifierType.featuredCosmeticBoost,
        ),
      );
    }
    if (today.weekday == DateTime.sunday) {
      modifiers.add(
        const DailyReturnModifier(type: DailyReturnModifierType.finalDayBonus),
      );
    }
    modifiers.sort((a, b) => a.priority.compareTo(b.priority));
    return modifiers.take(3).toList(growable: false);
  }

  double _streakMultiplierFor(int streak, List<DailyReturnModifier> modifiers) {
    final base = switch (streak) {
      >= 30 => 1.50,
      >= 14 => 1.35,
      >= 7 => 1.25,
      >= 3 => 1.10,
      _ => 1.0,
    };
    final dailyBonus =
        modifiers.any(
          (entry) => entry.type == DailyReturnModifierType.streakBonusActive,
        )
        ? 0.10
        : 0.0;
    return (base + dailyBonus).clamp(1.0, 1.75);
  }

  String _chestQualityFor(int streak) {
    if (streak >= 30) return 'Legendary streak chest';
    if (streak >= 14) return 'Epic streak chest';
    if (streak >= 7) return 'Rare streak chest';
    if (streak >= 3) return 'Warm streak chest';
    return 'Daily chest';
  }

  List<StreakMilestone> _milestonesFor(int streak) {
    const milestones = [
      StreakMilestone(days: 3, label: '3-day spark', rewardLabel: 'Warm chest'),
      StreakMilestone(days: 7, label: '7-day flame', rewardLabel: 'Rare chest'),
      StreakMilestone(
        days: 14,
        label: '14-day blaze',
        rewardLabel: 'Epic chest',
      ),
      StreakMilestone(
        days: 30,
        label: '30-day inferno',
        rewardLabel: 'Legendary chest',
      ),
    ];
    return milestones.where((entry) => streak >= entry.days).toList();
  }

  Future<void> _loadPersisted(String userId, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_storagePrefix$userId');
    final today = _dateOnly(now ?? DateTime.now());
    final currentWeek = _weekKey(today);
    if (raw == null) {
      _weekId = currentWeek;
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        _weekId = currentWeek;
        return;
      }
      final map = Map<String, dynamic>.from(decoded);
      _lastDailyRunDate = DateTime.tryParse(
        map['lastDailyRunDate']?.toString() ?? '',
      );
      _weekId = map['weekId']?.toString() ?? currentWeek;
      _weeklyDailyRuns = _asInt(map['weeklyDailyRuns']) ?? 0;
      _welcomeBackClaimedDateKey = map['welcomeBackClaimedDateKey']?.toString();
      _recoveryCompletedDateKey = map['recoveryCompletedDateKey']?.toString();
      _freezeProtectedDateKey = map['freezeProtectedDateKey']?.toString();
      _pendingComebackMissedDays =
          _asInt(map['pendingComebackMissedDays']) ?? 0;
      if (_weekId != currentWeek) {
        _weekId = currentWeek;
        _weeklyDailyRuns = 0;
      }
    } catch (_) {
      _weekId = currentWeek;
      _weeklyDailyRuns = 0;
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_storagePrefix$_userId',
      jsonEncode({
        'lastDailyRunDate': _lastDailyRunDate?.toIso8601String(),
        'weekId': _weekId,
        'weeklyDailyRuns': _weeklyDailyRuns,
        'welcomeBackClaimedDateKey': _welcomeBackClaimedDateKey,
        'recoveryCompletedDateKey': _recoveryCompletedDateKey,
        'freezeProtectedDateKey': _freezeProtectedDateKey,
        'pendingComebackMissedDays': _pendingComebackMissedDays,
      }),
    );
  }

  int _missedDaysSince(DateTime? lastActivity, DateTime today) {
    if (lastActivity == null) return 0;
    final diff = today.difference(_dateOnly(lastActivity)).inDays;
    return diff > 1 ? diff - 1 : 0;
  }

  int _daysSinceEpoch(DateTime value) {
    return _dateOnly(value).difference(DateTime(1970)).inDays;
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = ((hash * 31) + code) & 0x7fffffff;
    }
    return hash;
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _dateKey(DateTime value) {
    final day = _dateOnly(value);
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  String _weekKey(DateTime value) {
    final day = _dateOnly(value);
    final weekStart = day.subtract(Duration(days: day.weekday - 1));
    return _dateKey(weekStart);
  }

  String _safeUserId(String? userId) {
    final safe = userId?.trim();
    return safe == null || safe.isEmpty ? 'local' : safe;
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
