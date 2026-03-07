import 'package:flutter/foundation.dart';

import '../models/school_leaderboard_models.dart';
import '../services/api_service.dart';

class SchoolLeaderboardProvider extends ChangeNotifier {
  SchoolLeaderboardProvider({ApiService? api}) : api = api ?? ApiService();

  final ApiService api;

  final SchoolPagingController paging = SchoolPagingController();
  SchoolAggregateItem? mySchool;
  Object? error;
  final Map<int, SchoolLeaderboardDetail> _details = {};
  final Map<String, List<SchoolLeaderboardHistoryPoint>> _history = {};
  final Set<int> _loadingDetails = <int>{};

  String _mapRangeToPeriod(String range) {
    if (range == 'allTime') return 'all_time';
    return range; // weekly, etc.
  }

  Future<void> reload(String range) async {
    paging.reset();
    mySchool = null;
    error = null;
    notifyListeners();
    await loadMore(range);
  }

  Future<void> loadMore(String range) async {
    if (paging.isLoading || !paging.hasMore) return;

    paging.isLoading = true;
    error = null;
    notifyListeners();

    try {
      final data = await api.fetchSchoolVsSchoolLeaderboard(
        period: _mapRangeToPeriod(range),
        limit: 50,
        cursor: paging.cursor,
      );

      if (data == null) {
        paging.hasLoadedOnce = true;
        paging.isLoading = false;
        paging.hasMore = false;
        notifyListeners();
        return;
      }

      paging.items.addAll(data.items);
      paging.cursor = data.nextCursor;
      paging.hasMore = data.nextCursor != null;
      paging.hasLoadedOnce = true;
      mySchool = data.mySchool ?? mySchool;
    } catch (e) {
      error = e;
    } finally {
      paging.isLoading = false;
      notifyListeners();
    }
  }

  SchoolLeaderboardDetail? detailFor(int schoolId) => _details[schoolId];

  List<SchoolLeaderboardHistoryPoint> historyFor(int schoolId, String range) =>
      _history[_historyKey(schoolId, range)] ?? const [];

  bool isLoadingDetail(int schoolId) => _loadingDetails.contains(schoolId);

  Future<SchoolLeaderboardDetail?> loadDetail(int schoolId, String range) async {
    if (_loadingDetails.contains(schoolId)) {
      return _details[schoolId];
    }

    _loadingDetails.add(schoolId);
    notifyListeners();
    try {
      final detail = await api.fetchSchoolLeaderboardDetail(
        schoolId: schoolId,
        period: _mapRangeToPeriod(range),
      );
      if (detail != null) {
        _details[schoolId] = detail;
        if (detail.history.isNotEmpty) {
          _history[_historyKey(schoolId, range)] = detail.history;
        }
      }
      return detail;
    } finally {
      _loadingDetails.remove(schoolId);
      notifyListeners();
    }
  }

  Future<List<SchoolLeaderboardHistoryPoint>> loadHistory(
    int schoolId,
    String range,
  ) async {
    final cached = _history[_historyKey(schoolId, range)];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final history = await api.fetchSchoolLeaderboardHistory(
      schoolId: schoolId,
      period: _mapRangeToPeriod(range),
    );
    if (history != null) {
      _history[_historyKey(schoolId, range)] = history;
      notifyListeners();
      return history;
    }
    return const [];
  }

  String _historyKey(int schoolId, String range) => '$schoolId::$range';
}

