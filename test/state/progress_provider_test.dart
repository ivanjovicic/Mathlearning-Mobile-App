import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/state/progress_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'applyPracticeRoundReward queues pending progress and keeps permanent state unchanged',
    () async {
      final provider = ProgressProvider();

      await provider.applyPracticeRoundReward(xpEarned: 22);

      expect(provider.xp, 0);
      expect(provider.streak, 0);
      expect(provider.displayXp, 22);
      expect(provider.displayStreak, 1);
      expect(provider.hasPendingEvents, isTrue);
      expect(provider.isStreakDoneToday, isTrue);
    },
  );

  test(
    'applyPracticeRoundReward uses pending preview streak on a new day',
    () async {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      SharedPreferences.setMockInitialValues({
        'progress_last_streak_day_ms_v1': yesterday.millisecondsSinceEpoch,
      });

      final provider = ProgressProvider()..streak = 3;

      await provider.applyPracticeRoundReward(xpEarned: 10, now: today);

      expect(provider.xp, 0);
      expect(provider.streak, 3);
      expect(provider.displayXp, 10);
      expect(provider.displayStreak, 4);
      expect(provider.lastStreakDay, isNull);
    },
  );

  test('real user + API failure + no cache shows unavailable', () async {
    Future<ApiResult<Map<String, dynamic>>> fakeFail() async =>
        ApiResult.failure(
          ApiError(message: 'network', isOffline: true, errorCode: 'network'),
        );

    final provider = ProgressProvider(fetchProgressOverview: fakeFail);

    await provider.loadProgress();

    expect(provider.progressUnavailable, isTrue);
    expect(provider.totalAttempts, 0);
    expect(provider.accuracy, 0.0);
  });

  test('cached progress still loads when API fails', () async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'offline_cached_progress_v1': jsonEncode({
        'level': 2,
        'xp': 20,
        'streak': 4,
        'total_attempts': 10,
        'accuracy': 80.0,
        'last_streak_day_ms': nowMs,
      }),
    });

    Future<ApiResult<Map<String, dynamic>>> fakeFail() async =>
        ApiResult.failure(
          ApiError(message: 'network', isOffline: true, errorCode: 'network'),
        );

    final provider = ProgressProvider(fetchProgressOverview: fakeFail);

    await provider.loadProgress();

    expect(provider.progressUnavailable, isFalse);
    expect(provider.totalAttempts, 10);
    expect(provider.accuracy, 80.0);
    expect(provider.streak, 4);
  });

  test(
    'clearForUserSwitch clears visible pending progress only in memory',
    () async {
      final provider = ProgressProvider()
        ..xp = 20
        ..totalAttempts = 3;

      await provider.applyPracticeRoundReward(xpEarned: 10);

      expect(provider.displayXp, 30);
      expect(provider.hasPendingEvents, isTrue);

      provider.clearForUserSwitch();

      expect(provider.xp, 0);
      expect(provider.totalAttempts, 0);
      expect(provider.displayXp, 0);
      expect(provider.hasPendingEvents, isFalse);
    },
  );

  test('explicit demo mode still uses demo fallback when no cache', () async {
    Future<ApiResult<Map<String, dynamic>>> fakeFail() async =>
        ApiResult.failure(
          ApiError(message: 'network', isOffline: true, errorCode: 'network'),
        );

    final provider = ProgressProvider(fetchProgressOverview: fakeFail);
    provider.updateAuthContext(token: 'demo_token', isDemoMode: true);

    await provider.loadProgress();

    expect(provider.progressUnavailable, isFalse);
    expect(provider.totalAttempts, 15);
    expect(provider.accuracy, 75.0);
    expect(provider.streak, 3);
  });
}
