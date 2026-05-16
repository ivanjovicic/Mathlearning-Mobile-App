import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/services/user_scoped_storage.dart';

void main() {
  group('UserScopedStorage.clearUserScopedData', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('removes scoped and legacy keys for one user only', () async {
      SharedPreferences.setMockInitialValues({
        'user/userA/progress/level': 7,
        'user/userA/settings/theme': 'dark',
        'user/userB/progress/level': 4,
        'user/userB/settings/theme': 'light',
        'daily_run.state.v1.userA.current': 'remove-me',
        'daily_return.state.v1.userA': 'remove-me',
        'cosmetic_target_state_v1.userA.primary': 'remove-me',
        'weekly_featured_cosmetic_state_v1.userA.active': 'remove-me',
        'season_progress.v1.userA.stage': 'remove-me',
        'player_identity.v1.title.userA.hero': 'remove-me',
        'player_identity.v1.favorite.userA.skin': 'remove-me',
        'cached_srs_daily_questions_userA': 'remove-me',
        'cached_srs_daily_questions_updated_at_userA': 'remove-me',
        'pending_srs_updates_userA': 'remove-me',
        'user_progress': '{"level":1}',
        'offline_cached_progress_v1': '{"level":2}',
        'pending_progress_events_v1': '[]',
        'progress_last_streak_day_ms_v1': 123456789,
        'unrelated_key': 'keep-me',
      });

      await UserScopedStorage.clearUserScopedData('userA');

      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getKeys(), contains('user/userB/progress/level'));
      expect(prefs.getKeys(), contains('user/userB/settings/theme'));
      expect(prefs.getKeys(), contains('unrelated_key'));

      expect(prefs.getKeys(), isNot(contains('user/userA/progress/level')));
      expect(prefs.getKeys(), isNot(contains('user/userA/settings/theme')));

      expect(prefs.getKeys(), isNot(contains('daily_run.state.v1.userA.current')));
      expect(prefs.getKeys(), isNot(contains('daily_return.state.v1.userA')));
      expect(prefs.getKeys(), isNot(contains('cosmetic_target_state_v1.userA.primary')));
      expect(prefs.getKeys(), isNot(contains('weekly_featured_cosmetic_state_v1.userA.active')));
      expect(prefs.getKeys(), isNot(contains('season_progress.v1.userA.stage')));
      expect(prefs.getKeys(), isNot(contains('player_identity.v1.title.userA.hero')));
      expect(prefs.getKeys(), isNot(contains('player_identity.v1.favorite.userA.skin')));
      expect(prefs.getKeys(), isNot(contains('cached_srs_daily_questions_userA')));
      expect(prefs.getKeys(), isNot(contains('cached_srs_daily_questions_updated_at_userA')));
      expect(prefs.getKeys(), isNot(contains('pending_srs_updates_userA')));

      expect(prefs.getKeys(), isNot(contains('user_progress')));
      expect(prefs.getKeys(), isNot(contains('offline_cached_progress_v1')));
      expect(prefs.getKeys(), isNot(contains('pending_progress_events_v1')));
      expect(prefs.getKeys(), isNot(contains('progress_last_streak_day_ms_v1')));
    });
  });
}
