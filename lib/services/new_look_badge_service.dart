import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the current user has a "NEW LOOK" badge to show
/// on their own profile/leaderboard row.
///
/// The badge is set whenever the user equips a cosmetic and auto-expires
/// 24 hours later. It is ONLY shown for the local user — never synthesised
/// for other users based on their rank or ID.
class NewLookBadgeService {
  NewLookBadgeService._();
  static final NewLookBadgeService instance = NewLookBadgeService._();

  static const _key = 'new_look_badge_set_at';
  static const _ttl = Duration(hours: 24);

  /// Records the current time as the equip timestamp.
  Future<void> markEquipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _key,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns true if the badge was set less than 24 hours ago.
  Future<bool> isActive() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_key);
    if (raw == null) return false;
    final setAt = DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.now().difference(setAt) < _ttl;
  }

  /// Clears the badge immediately (e.g., user dismissed it).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
