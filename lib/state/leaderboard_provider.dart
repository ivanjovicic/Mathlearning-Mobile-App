import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import '../services/leaderboard_api_service.dart';

enum LeaderboardScope { global, school, faculty, friends }

enum LeaderboardBoard { users, schools }

extension LeaderboardScopeX on LeaderboardScope {
  String get apiValue {
    switch (this) {
      case LeaderboardScope.global:
        return 'global';
      case LeaderboardScope.school:
        return 'school';
      case LeaderboardScope.faculty:
        return 'global';
      case LeaderboardScope.friends:
        return 'friends';
    }
  }
}

class LeaderboardProvider extends ChangeNotifier {
  LeaderboardProvider({LeaderboardApiService? api})
    : api = api ?? LeaderboardApiService();

  final LeaderboardApiService api;

  String? token;
  bool _isDemoMode = false;
  String? _lastToken;
  bool _lastDemoMode = false;
  LeaderboardPeriod _currentPeriod = LeaderboardPeriod.week;

  final Map<LeaderboardScope, LeaderboardPagingController<LeaderboardItem>>
  _paging = <LeaderboardScope, LeaderboardPagingController<LeaderboardItem>>{
    for (final scope in LeaderboardScope.values)
      scope: LeaderboardPagingController<LeaderboardItem>(),
  };

  final Map<LeaderboardScope, LeaderboardMe?> _me =
      <LeaderboardScope, LeaderboardMe?>{
        for (final scope in LeaderboardScope.values) scope: null,
      };

  final Map<LeaderboardScope, Object?> _error = <LeaderboardScope, Object?>{
    for (final scope in LeaderboardScope.values) scope: null,
  };

  final Map<LeaderboardScope, LeaderboardPeriod?> _loadedUserPeriods =
      <LeaderboardScope, LeaderboardPeriod?>{
        for (final scope in LeaderboardScope.values) scope: null,
      };

  final LeaderboardPagingController<SchoolLeaderboardEntry> _schoolPaging =
      LeaderboardPagingController<SchoolLeaderboardEntry>();
  LeaderboardPeriod? _loadedSchoolPeriod;
  SchoolLeaderboardEntry? _currentSchool;
  Object? _schoolError;

  List<RivalLeaderboardEntry> _rivals = const <RivalLeaderboardEntry>[];
  LeaderboardPeriod? _loadedRivalsPeriod;
  Object? _rivalsError;
  bool _isLoadingRivals = false;

  int? currentUserId;

  LeaderboardPeriod get currentPeriod => _currentPeriod;

  LeaderboardPagingController<LeaderboardItem> pagingFor(
    LeaderboardScope scope,
  ) => _paging[scope]!;

  List<LeaderboardItem> itemsFor(LeaderboardScope scope) =>
      List.unmodifiable(_paging[scope]!.items);

  LeaderboardMe? meFor(LeaderboardScope scope) => _me[scope];

  Object? errorFor(LeaderboardScope scope) => _error[scope];

  bool hasLoaded(LeaderboardScope scope) => _paging[scope]!.hasLoadedOnce;

  LeaderboardPagingController<SchoolLeaderboardEntry> get schoolPaging =>
      _schoolPaging;

  List<SchoolLeaderboardEntry> get schoolItems =>
      List.unmodifiable(_schoolPaging.items);

  SchoolLeaderboardEntry? get currentSchoolEntry => _currentSchool;

  Object? get schoolError => _schoolError;

  List<RivalLeaderboardEntry> get rivals => List.unmodifiable(_rivals);

  Object? get rivalsError => _rivalsError;

  bool get isLoadingRivals => _isLoadingRivals;

  bool get isLoadingSchools => _schoolPaging.isLoading;

  void resetAll() {
    for (final scope in LeaderboardScope.values) {
      _paging[scope]!.reset();
      _me[scope] = null;
      _error[scope] = null;
      _loadedUserPeriods[scope] = null;
    }
    _schoolPaging.reset();
    _loadedSchoolPeriod = null;
    _currentSchool = null;
    _schoolError = null;
    _rivals = const <RivalLeaderboardEntry>[];
    _loadedRivalsPeriod = null;
    _rivalsError = null;
    _isLoadingRivals = false;
    notifyListeners();
  }

  void onTokenUpdated(String? newToken, {bool isDemoMode = false}) {
    if (_lastToken == newToken && _lastDemoMode == isDemoMode) return;
    _lastToken = newToken;
    _lastDemoMode = isDemoMode;
    token = newToken;
    _isDemoMode = isDemoMode;
    resetAll();
  }

  void setCurrentUserId(int? userId) {
    if (currentUserId == userId) {
      return;
    }
    currentUserId = userId;
    notifyListeners();
  }

  Future<void> changePeriod(
    LeaderboardPeriod period, {
    required LeaderboardBoard board,
  }) async {
    final didChange = _currentPeriod != period;
    _currentPeriod = period;
    if (didChange) {
      notifyListeners();
    }

    if (board == LeaderboardBoard.users) {
      await Future.wait<void>(<Future<void>>[
        reloadScope(LeaderboardScope.global, period: period),
        fetchRivals(period: period),
      ]);
      return;
    }

    await reloadSchoolLeaderboard(period: period);
  }

  Future<void> ensureUsersLoaded() async {
    final period = _currentPeriod;
    final shouldReloadUsers =
        !hasLoaded(LeaderboardScope.global) ||
        _loadedUserPeriods[LeaderboardScope.global] != period;
    final shouldReloadRivals = _loadedRivalsPeriod != period;

    final work = <Future<void>>[];
    if (shouldReloadUsers) {
      work.add(reloadScope(LeaderboardScope.global, period: period));
    }
    if (shouldReloadRivals) {
      work.add(fetchRivals(period: period));
    }

    if (work.isEmpty) {
      return;
    }

    await Future.wait<void>(work);
  }

  Future<void> ensureSchoolsLoaded() async {
    if (_schoolPaging.hasLoadedOnce && _loadedSchoolPeriod == _currentPeriod) {
      return;
    }
    await reloadSchoolLeaderboard(period: _currentPeriod);
  }

  Future<void> loadGlobal([LeaderboardPeriod? period]) async {
    await reloadScope(LeaderboardScope.global, period: period);
  }

  Future<void> loadFriends([LeaderboardPeriod? period]) async {
    await reloadScope(LeaderboardScope.friends, period: period);
  }

  Future<void> loadSchool([LeaderboardPeriod? period]) async {
    await reloadScope(LeaderboardScope.school, period: period);
  }

  Future<void> loadFaculty([LeaderboardPeriod? period]) async {
    await reloadScope(LeaderboardScope.faculty, period: period);
  }

  Future<void> reloadScope(
    LeaderboardScope scope, {
    LeaderboardPeriod? period,
  }) async {
    final paging = _paging[scope]!;
    paging.reset();
    _me[scope] = null;
    _error[scope] = null;
    _loadedUserPeriods[scope] = null;
    notifyListeners();
    await loadMore(scope, period: period);
  }

  Future<void> loadMore(
    LeaderboardScope scope, {
    LeaderboardPeriod? period,
  }) async {
    final paging = _paging[scope]!;
    final resolvedPeriod = period ?? _currentPeriod;
    if (paging.isLoading || !paging.hasMore) {
      return;
    }

    paging.isLoading = true;
    _error[scope] = null;
    notifyListeners();

    try {
      if (_isDemoMode) {
        paging.hasLoadedOnce = true;
        paging.isLoading = false;
        paging.hasMore = false;
        _loadedUserPeriods[scope] = resolvedPeriod;
        notifyListeners();
        return;
      }

      final data = await api.fetchLeaderboard(
        scope: scope.apiValue,
        period: resolvedPeriod.apiValue,
        limit: 50,
        cursor: paging.cursor,
      );

      if (data == null) {
        paging.hasLoadedOnce = true;
        paging.isLoading = false;
        paging.hasMore = false;
        _loadedUserPeriods[scope] = resolvedPeriod;
        notifyListeners();
        return;
      }

      paging.items.addAll(data.items);
      paging.cursor = data.nextCursor;
      paging.hasMore = data.nextCursor != null;
      paging.hasLoadedOnce = true;
      _me[scope] = data.me ?? _me[scope];
      _loadedUserPeriods[scope] = resolvedPeriod;
    } catch (error) {
      _error[scope] = error;
    } finally {
      paging.isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadSchoolLeaderboard({LeaderboardPeriod? period}) async {
    _schoolPaging.reset();
    _schoolError = null;
    _currentSchool = null;
    _loadedSchoolPeriod = null;
    notifyListeners();
    await loadMoreSchools(period: period);
  }

  Future<void> loadMoreSchools({LeaderboardPeriod? period}) async {
    final resolvedPeriod = period ?? _currentPeriod;
    if (_schoolPaging.isLoading || !_schoolPaging.hasMore) {
      return;
    }

    _schoolPaging.isLoading = true;
    _schoolError = null;
    notifyListeners();

    try {
      if (_isDemoMode) {
        _schoolPaging.hasLoadedOnce = true;
        _schoolPaging.isLoading = false;
        _schoolPaging.hasMore = false;
        _loadedSchoolPeriod = resolvedPeriod;
        notifyListeners();
        return;
      }

      final data = await api.fetchSchoolLeaderboard(
        period: resolvedPeriod.apiValue,
        limit: 50,
        cursor: _schoolPaging.cursor,
      );

      if (data == null) {
        _schoolPaging.hasLoadedOnce = true;
        _schoolPaging.isLoading = false;
        _schoolPaging.hasMore = false;
        _loadedSchoolPeriod = resolvedPeriod;
        notifyListeners();
        return;
      }

      _schoolPaging.items.addAll(data.items);
      _schoolPaging.cursor = data.nextCursor;
      _schoolPaging.hasMore = data.nextCursor != null;
      _schoolPaging.hasLoadedOnce = true;
      _currentSchool = data.currentSchool ?? _currentSchool;
      _loadedSchoolPeriod = resolvedPeriod;
    } catch (error) {
      _schoolError = error;
    } finally {
      _schoolPaging.isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRivals({LeaderboardPeriod? period}) async {
    final resolvedPeriod = period ?? _currentPeriod;
    if (_isLoadingRivals) {
      return;
    }

    _isLoadingRivals = true;
    _rivalsError = null;
    notifyListeners();

    try {
      if (_isDemoMode) {
        _rivals = const <RivalLeaderboardEntry>[];
        _loadedRivalsPeriod = resolvedPeriod;
        return;
      }

      final data = await api.fetchRivals(period: resolvedPeriod.apiValue);

      _rivals = data ?? const <RivalLeaderboardEntry>[];
      _loadedRivalsPeriod = resolvedPeriod;
    } catch (error) {
      _rivalsError = error;
    } finally {
      _isLoadingRivals = false;
      notifyListeners();
    }
  }

  LeaderboardMe? get currentUser => _me[LeaderboardScope.global];

  LeaderboardPagingController<LeaderboardItem> get paging =>
      _paging[LeaderboardScope.global]!;

  void searchLeaderboard(
    String query,
    LeaderboardScope scope,
    LeaderboardPeriod period,
  ) {}

  bool get isLoading => _paging[LeaderboardScope.global]!.isLoading;

  bool get hasError => _error[LeaderboardScope.global] != null;

  void setErrorForTesting(Object? error) {
    _error[LeaderboardScope.global] = error;
    notifyListeners();
  }

  void retry() {
    reloadScope(LeaderboardScope.global, period: _currentPeriod);
  }
}
