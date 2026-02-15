import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import '../services/api_service.dart';

enum LeaderboardScope { global, school, faculty, friends }

extension LeaderboardScopeX on LeaderboardScope {
  String get apiValue {
    switch (this) {
      case LeaderboardScope.global:
        return 'global';
      case LeaderboardScope.school:
        return 'school';
      case LeaderboardScope.faculty:
        return 'faculty';
      case LeaderboardScope.friends:
        return 'friends';
    }
  }
}

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider({ApiService? api}) : api = api ?? ApiService();

  final ApiService api;

  String? token;
  String? _lastToken;

  final Map<LeaderboardScope, LeaderboardPagingController> _paging = {
    for (final s in LeaderboardScope.values) s: LeaderboardPagingController(),
  };

  final Map<LeaderboardScope, LeaderboardMe?> _me = {
    for (final s in LeaderboardScope.values) s: null,
  };

  final Map<LeaderboardScope, Object?> _error = {
    for (final s in LeaderboardScope.values) s: null,
  };

  LeaderboardPagingController pagingFor(LeaderboardScope scope) => _paging[scope]!;

  List<LeaderboardItem> itemsFor(LeaderboardScope scope) =>
      List.unmodifiable(_paging[scope]!.items);

  LeaderboardMe? meFor(LeaderboardScope scope) => _me[scope];

  Object? errorFor(LeaderboardScope scope) => _error[scope];

  bool hasLoaded(LeaderboardScope scope) => _paging[scope]!.hasLoadedOnce;

  void resetAll() {
    for (final s in LeaderboardScope.values) {
      _paging[s]!.reset();
      _me[s] = null;
      _error[s] = null;
    }
    notifyListeners();
  }

  /// Call when auth token changes, to avoid showing stale data from a previous user.
  void onTokenUpdated(String? newToken) {
    if (_lastToken == newToken) return;
    _lastToken = newToken;
    token = newToken;
    resetAll();
  }

  Future<void> loadGlobal(String range) async {
    await reloadScope(LeaderboardScope.global, range);
  }

  Future<void> loadFriends(String range) async {
    await reloadScope(LeaderboardScope.friends, range);
  }

  Future<void> loadSchool(String range) async {
    await reloadScope(LeaderboardScope.school, range);
  }

  Future<void> loadFaculty(String range) async {
    await reloadScope(LeaderboardScope.faculty, range);
  }

  Future<void> reloadScope(LeaderboardScope scope, String range) async {
    final p = _paging[scope]!;
    p.reset();
    _me[scope] = null;
    _error[scope] = null;
    notifyListeners();
    await loadMore(scope, range);
  }

  String _mapRangeToPeriod(String range) {
    // Preserve existing UI values, while speaking the backend shape.
    if (range == 'allTime') return 'all_time';
    return range; // weekly, etc.
  }

  Future<void> loadMore(LeaderboardScope scope, String range) async {
    final p = _paging[scope]!;
    if (p.isLoading || !p.hasMore) return;

    p.isLoading = true;
    _error[scope] = null;
    notifyListeners();

    try {
      // Skip API call if using demo token (backend not ready)
      if (token?.startsWith('demo_') == true) {
        p.hasLoadedOnce = true;
        p.isLoading = false;
        p.hasMore = false;
        notifyListeners();
        return;
      }

      final data = await api.fetchLeaderboard(
        scope: scope.apiValue,
        period: _mapRangeToPeriod(range),
        limit: 50,
        cursor: p.cursor,
      );

      if (data == null) {
        p.hasLoadedOnce = true;
        p.isLoading = false;
        p.hasMore = false;
        notifyListeners();
        return;
      }

      p.items.addAll(data.items);
      p.cursor = data.nextCursor;
      p.hasMore = data.nextCursor != null;
      p.hasLoadedOnce = true;
      _me[scope] = data.me ?? _me[scope];
    } catch (e) {
      _error[scope] = e;
    } finally {
      p.isLoading = false;
      notifyListeners();
    }
  }
}
