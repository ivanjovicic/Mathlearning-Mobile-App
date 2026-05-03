import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/state/progress_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('applyPracticeRoundReward awards xp and starts today streak', () async {
    final provider = ProgressProvider();

    await provider.applyPracticeRoundReward(xpEarned: 22);

    expect(provider.xp, 22);
    expect(provider.streak, 1);
    expect(provider.isStreakDoneToday, isTrue);
  });

  test(
    'applyPracticeRoundReward advances an existing streak on a new day',
    () async {
      final today = DateTime.now();
      final yesterday = DateTime(today.year, today.month, today.day - 1);
      SharedPreferences.setMockInitialValues({
        'progress_last_streak_day_ms_v1': yesterday.millisecondsSinceEpoch,
      });

      final provider = ProgressProvider()..streak = 3;

      await provider.applyPracticeRoundReward(xpEarned: 10, now: today);

      expect(provider.xp, 10);
      expect(provider.streak, 4);
      expect(
        provider.lastStreakDay,
        DateTime(today.year, today.month, today.day),
      );
    },
  );
}
