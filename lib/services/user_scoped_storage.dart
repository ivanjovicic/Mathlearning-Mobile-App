import 'package:shared_preferences/shared_preferences.dart';

class UserScopedStorage {
  static const String _rootPrefix = 'user/';

  static String normalizeUserId(String? userId) {
    final value = userId?.trim();
    if (value == null || value.isEmpty) {
      return 'local';
    }
    return value;
  }

  static String scopedPrefix(String userId, String scope) {
    final normalizedUser = normalizeUserId(userId);
    final normalizedScope = scope.trim().replaceAll('\\', '/');
    return '$_rootPrefix$normalizedUser/$normalizedScope';
  }

  static String scopedKey(String userId, String scope, String key) {
    final prefix = scopedPrefix(userId, scope);
    final normalizedKey = key.trim().replaceAll('\\', '/');
    return '$prefix/$normalizedKey';
  }

  static Future<void> clearUserScopedData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedUser = normalizeUserId(userId);
    final keys = prefs.getKeys();

    final newPrefix = '$_rootPrefix$normalizedUser/';
    final legacyPrefixes = <String>[
      'daily_run.state.v1.$normalizedUser.',
      'daily_return.state.v1.$normalizedUser',
      'cosmetic_target_state_v1.$normalizedUser',
      'weekly_featured_cosmetic_state_v1.$normalizedUser',
      'season_progress.v1.$normalizedUser.',
      'player_identity.v1.title.$normalizedUser',
      'player_identity.v1.favorite.$normalizedUser',
      'cached_srs_daily_questions_$normalizedUser',
      'cached_srs_daily_questions_updated_at_$normalizedUser',
      'pending_srs_updates_$normalizedUser',
    ];

    final legacyExactKeys = <String>{
      'user_progress',
      'offline_cached_progress_v1',
      'pending_progress_events_v1',
      'progress_last_streak_day_ms_v1',
    };

    for (final key in keys) {
      final isNewScoped = key.startsWith(newPrefix);
      final isLegacyPrefixed = legacyPrefixes.any(key.startsWith);
      final isLegacyExact = legacyExactKeys.contains(key);
      if (isNewScoped || isLegacyPrefixed || isLegacyExact) {
        await prefs.remove(key);
      }
    }
  }
}
