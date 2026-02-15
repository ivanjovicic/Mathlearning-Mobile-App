import 'package:flutter/foundation.dart';

import '../models/school_leaderboard_models.dart';
import '../services/api_service.dart';

class SchoolLeaderboardProvider extends ChangeNotifier {
  SchoolLeaderboardProvider({ApiService? api}) : api = api ?? ApiService();

  final ApiService api;

  final SchoolPagingController paging = SchoolPagingController();
  SchoolAggregateItem? mySchool;
  Object? error;

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
}

