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
  LeaderboardEntry? myGlobalRank;
  LeaderboardEntry? myFriendsRank;

  bool isLoading = false;

  Future<void> loadGlobal(String range) async {
    isLoading = true;
    notifyListeners();

    try {
      // Skip API call if using demo token (backend not ready)
      if (token?.startsWith('demo_') != true) {
        final data = await api.getGlobalLeaderboard(range, 50, token);
        if (data != null) {
          global = data.map((e) => LeaderboardEntry.fromJson(e)).toList();

          // Also fetch my rank
          await _loadMyRank(range, isGlobal: true);

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
    myGlobalRank = null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadFriends(String range) async {
    isLoading = true;
    notifyListeners();

    try {
      // Skip API call if using demo token (backend not ready)
      if (token?.startsWith('demo_') != true) {
        final data = await api.getFriendsLeaderboard(range, 50, token);
        if (data != null) {
          friends = data.map((e) => LeaderboardEntry.fromJson(e)).toList();

          // Also fetch my rank
          await _loadMyRank(range, isGlobal: false);

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
    myFriendsRank = null;
    isLoading = false;
    notifyListeners();
  }

  /// Fetch the current user's rank, even if they're not in the top 50
  Future<void> _loadMyRank(String range, {required bool isGlobal}) async {
    try {
      final data = await api.getUserRank(range, token);
      if (data != null) {
        final entry = LeaderboardEntry.fromJson(data);
        if (isGlobal) {
          // Only store if user is NOT already in the list
          final alreadyInList = global.any((e) => e.userId == entry.userId);
          myGlobalRank = alreadyInList ? null : entry;
        } else {
          final alreadyInList = friends.any((e) => e.userId == entry.userId);
          myFriendsRank = alreadyInList ? null : entry;
        }
      }
    } catch (e) {
      debugPrint('Failed to load my rank: $e');
    }
  }
}
