import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/state/daily_return_provider.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/streak_freeze_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('streak preservation uses freeze instead of breaking streak', () async {
    final now = DateTime(2026, 5, 15);
    final lastActive = DateTime(2026, 5, 13);
    SharedPreferences.setMockInitialValues({
      'progress_last_streak_day_ms_v1': lastActive.millisecondsSinceEpoch,
      'streak_freeze_count_v1': 1,
    });

    final freeze = StreakFreezeProvider();
    await freeze.load();
    final progress = ProgressProvider()..streak = 6;
    progress.updateStreakFreezeProvider(freeze);

    final roll = await progress.rollDailyStreakIfNeeded(now: now);
    expect(roll.freezesUsed, 1);
    expect(roll.streakBroken, isFalse);
    expect(progress.streak, 6);

    final engine = DailyReturnProvider();
    await engine.load(
      userId: 'user-1',
      now: now,
      progress: progress,
      streakFreeze: freeze,
    );

    expect(engine.state?.streakProtectedToday, isTrue);
    expect(engine.state?.primaryMessage, 'Streak freeze protected you');
  });

  test('comeback rewards appear after missed days and modify chest', () async {
    final firstDay = DateTime(2026, 5, 12);
    final returnDay = DateTime(2026, 5, 15);
    final engine = DailyReturnProvider();
    await engine.load(userId: 'user-1', now: firstDay);
    await engine.recordDailyRunCompleted(now: firstDay);

    final progress = ProgressProvider()..streak = 0;
    await engine.load(userId: 'user-1', now: returnDay, progress: progress);

    expect(engine.state?.hasComebackReward, isTrue);
    expect(engine.state?.comebackReward?.missedDays, 2);

    const base = DailyChestReward(
      xp: 40,
      coins: 10,
      cosmeticFragment: 'Comet Frame Fragment',
    );
    final boosted = engine.applyRewardModifiers(base, now: returnDay);

    expect(boosted.isComebackChest, isTrue);
    expect(boosted.coins, 15);
    expect(boosted.xp, greaterThan(base.xp));
    expect(boosted.modifierLabels, contains('Welcome-back chest'));
  });

  test('modifier rotation is deterministic and changes by date', () async {
    final engine = DailyReturnProvider();
    await engine.load(userId: 'user-1', now: DateTime(2026, 5, 15));
    final firstTypes = engine.state!.modifiers.map((e) => e.type).toList();

    await engine.load(userId: 'user-1', now: DateTime(2026, 5, 16));
    final secondTypes = engine.state!.modifiers.map((e) => e.type).toList();

    expect(firstTypes, isNot(secondTypes));
    expect(firstTypes.length, lessThanOrEqualTo(3));
    expect(secondTypes.length, lessThanOrEqualTo(3));
  });

  test(
    'double fragment modifier upgrades reward copies without fake labels',
    () async {
      final engine = DailyReturnProvider();
      DateTime? doubleDay;
      for (var day = 15; day < 25; day++) {
        final now = DateTime(2026, 5, day);
        await engine.load(userId: 'user-1', now: now);
        if (engine.state!.hasDoubleFragmentDay) {
          doubleDay = now;
          break;
        }
      }

      expect(doubleDay, isNotNull);
      const base = DailyChestReward(
        xp: 25,
        coins: 8,
        cosmeticFragment: 'Nova Trail Fragment',
      );
      final boosted = engine.applyRewardModifiers(base, now: doubleDay);

      expect(boosted.fragmentCopies, 2);
      expect(boosted.modifierLabels, contains('2x fragment boost active'));
    },
  );

  test(
    'recordDailyRunCompleted completes recovery mission and weekly goal',
    () async {
      final engine = DailyReturnProvider();
      await engine.load(userId: 'user-1', now: DateTime(2026, 5, 11));
      await engine.recordDailyRunCompleted(now: DateTime(2026, 5, 11));
      await engine.load(userId: 'user-1', now: DateTime(2026, 5, 14));

      expect(engine.state?.comebackReward?.recoveryComplete, isFalse);

      final progress = ProgressProvider()..streak = 1;
      await engine.recordDailyRunCompleted(
        now: DateTime(2026, 5, 14),
        progress: progress,
      );

      expect(engine.state?.comebackReward?.recoveryComplete, isTrue);

      for (var day = 15; day <= 17; day++) {
        await engine.recordDailyRunCompleted(now: DateTime(2026, 5, day));
      }

      final weeklyGoal = engine.state!.weeklyGoals.firstWhere(
        (goal) => goal.id == 'weekly_daily_runs',
      );
      expect(weeklyGoal.progress, 5);
      expect(weeklyGoal.isComplete, isTrue);
    },
  );

  test('streak milestones and multiplier scale from real streak', () async {
    final progress = ProgressProvider()..streak = 14;
    final engine = DailyReturnProvider();
    await engine.load(
      userId: 'user-1',
      now: DateTime(2026, 5, 15),
      progress: progress,
    );

    expect(engine.state!.streakMultiplier, greaterThanOrEqualTo(1.35));
    expect(engine.state!.chestQualityLabel, 'Epic streak chest');
    expect(
      engine.state!.reachedMilestones.map((entry) => entry.days),
      containsAll(<int>[3, 7, 14]),
    );
  });

  test('urgency stays compact to avoid notification fatigue', () async {
    final engine = DailyReturnProvider();
    await engine.load(userId: 'user-1', now: DateTime(2026, 5, 17));

    expect(engine.state!.modifiers.length, lessThanOrEqualTo(3));
    expect(
      engine.state!.modifiers.map((entry) => entry.label).join(' '),
      isNot(contains('Ends in')),
    );
  });
}
