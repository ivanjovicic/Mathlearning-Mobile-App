import 'dart:math' as math;

enum StreakVisualState {
  normal,
  atRisk,
  protected,
  lost,
}

class StreakStateMachine {
  StreakVisualState state;
  int streakDays;
  int freezeCount;

  StreakStateMachine({
    required this.state,
    required this.streakDays,
    required this.freezeCount,
  });

  void syncCounts({required int streakDays, required int freezeCount}) {
    this.streakDays = streakDays;
    this.freezeCount = freezeCount;
  }

  /// Call when user answers at least one question today.
  void onDailyActivity() {
    if (state == StreakVisualState.lost) {
      state = StreakVisualState.normal;
      streakDays = 1;
      return;
    }
    state = StreakVisualState.normal;
  }

  /// Call on app open / daily check.
  ///
  /// [daysSinceLastActivity]:
  /// - 0 => already active today
  /// - 1 => last activity was yesterday (still consecutive)
  /// - >=2 => missed at least one day
  ///
  /// Returns how many freezes were consumed.
  int onStreakValidation({required int daysSinceLastActivity}) {
    if (daysSinceLastActivity <= 1) {
      state = StreakVisualState.normal;
      return 0;
    }

    final missedDays = daysSinceLastActivity - 1;
    final used = math.min(freezeCount, missedDays);
    freezeCount -= used;

    if (used > 0) {
      state = StreakVisualState.protected;
    }

    if (used < missedDays) {
      streakDays = 0;
      state = StreakVisualState.lost;
    }

    return used;
  }

  void onAtRisk() {
    if (state == StreakVisualState.normal) {
      state = StreakVisualState.atRisk;
    }
  }

  void clearProtected() {
    if (state == StreakVisualState.protected) {
      state = StreakVisualState.normal;
    }
  }
}

