import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final int level;
  final int xp;
  final int weeklyXp;
  final int streak;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.level,
    required this.xp,
    required this.weeklyXp,
    required this.streak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) {
    return LeaderboardEntry(
      rank: j['rank'],
      userId: j['userId'],
      name: j['displayName'],
      level: j['level'],
      xp: j['xp'],
      weeklyXp: j['weeklyXp'],
      streak: j['streak'],
    );
  }
}

class LeaderboardProvider extends ChangeNotifier {
  final api = ApiService();

  String? token;

  List<LeaderboardEntry> global = [];
  List<LeaderboardEntry> friends = [];

  bool isLoading = false;

  Future<void> loadGlobal(String range) async {
    isLoading = true;
    notifyListeners();

    try {
      // Skip API call if using demo token (backend not ready)
      if (token?.startsWith('demo_token') != true) {
        final data = await api.getGlobalLeaderboard(range, 50, token);
        if (data != null) {
          global = data
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList();
          isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Global leaderboard API failed: $e');
    }

    // Demo data fallback (when using demo token or API fails)
    global = [];
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadFriends(String range) async {
    isLoading = true;
    notifyListeners();

    try {
      // Skip API call if using demo token (backend not ready)
      if (token?.startsWith('demo_token') != true) {
        final data = await api.getFriendsLeaderboard(range, 50, token);
        if (data != null) {
          friends = data
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList();
          isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Friends leaderboard API failed: $e');
    }

    // Demo data fallback (when using demo token or API fails)
    friends = [];
    isLoading = false;
    notifyListeners();
  }
}
