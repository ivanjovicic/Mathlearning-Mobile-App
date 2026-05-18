import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mathlearning/models/hint_models.dart';
import 'package:mathlearning/models/leaderboard_models.dart';
import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/coin_provider.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';

class TestAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isLoading;
  bool _isResolved;
  final String? _error;
  bool _isAuthenticated;
  String? _token;
  String? _userId;
  String? _username;

  TestAuthProvider({
    bool isLoading = false,
    bool isResolved = true,
    bool isAuthenticated = true,
    String? token = 'demo_token_test',
    String? userId = '1',
    String? username = 'Alex',
    String? error,
  }) : _isLoading = isLoading,
       _isResolved = isResolved,
       _isAuthenticated = isAuthenticated,
       _token = token,
       _userId = userId,
       _username = username,
       _error = error;

  void setUser({
    required bool isAuthenticated,
    String? token,
    String? userId,
    String? username,
  }) {
    _isAuthenticated = isAuthenticated;
    _token = token;
    _userId = userId;
    _username = username;
    notifyListeners();
  }

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isResolved => _isResolved;

  @override
  String? get error => _error;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get token => _token;

  @override
  String? get userId => _userId;

  @override
  String? get username => _username;

  @override
  bool get isDemoMode => _token?.startsWith('demo_') ?? false;

  @override
  Future<bool> autoLogin() async {
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    _isLoading = false;
    _isResolved = true;
    notifyListeners();
    return _isAuthenticated;
  }

  @override
  Future<bool> login(String username, String password) async {
    _isAuthenticated = true;
    _isResolved = true;
    _username = username;
    _token = 'demo_token_login';
    notifyListeners();
    return true;
  }

  @override
  Future<bool> register(String username, String password, String email) async {
    return true;
  }

  @override
  Future<void> logout() async {
    _isAuthenticated = false;
    _isResolved = true;
    _token = null;
    _userId = null;
    _username = null;
    notifyListeners();
  }
}

class TestCoinProvider extends ChangeNotifier implements CoinProvider {
  int _coins;
  final UserDailyHints? _dailyHints;
  bool _isLoading;

  TestCoinProvider({
    int coins = 10,
    bool isLoading = false,
    UserDailyHints? dailyHints,
  }) : _coins = coins,
       _isLoading = isLoading,
       _dailyHints =
           dailyHints ??
           UserDailyHints(userId: 'demo', date: DateTime(2026, 2, 6));

  @override
  int get coins => _coins;

  @override
  UserDailyHints? get dailyHints => _dailyHints;

  @override
  bool get isLoading => _isLoading;

  @override
  Future<void> loadCoinsAndHints({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    _isLoading = false;
    notifyListeners();
  }

  @override
  bool canAffordHint(String hintType) => true;

  @override
  String getHintCostText(String hintType) => 'BESPLATNO';

  @override
  Future<bool> useHint(String hintType) async => true;

  @override
  void addCoins(int amount) {
    _coins += amount;
    notifyListeners();
  }

  @override
  bool canAfford(int amount) => _coins >= amount;

  @override
  bool trySpendCoins(int amount) {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _coins -= amount;
    notifyListeners();
    return true;
  }
}

class TestQuizProvider extends QuizProvider {
  TestQuizProvider({
    Future<int> Function()? onGetDailySrsCount,
    List<Question>? reviewQuestions,
    List<Question>? quizQuestions,
    this.pendingAnswersCount = 0,
  }) : _onGetDailySrsCount = onGetDailySrsCount ?? (() async => 0),
       _reviewQuestions = reviewQuestions ?? <Question>[],
       _quizQuestions = quizQuestions ?? <Question>[];

  final Future<int> Function() _onGetDailySrsCount;
  int getDailySrsCountCalls = 0;

  int pendingAnswersCount;

  final List<Question> _reviewQuestions;
  final List<Question> _quizQuestions;

  int _questionNumber = 1;

  @override
  List<Question> get questions => List.unmodifiable(_reviewQuestions);

  @override
  Future<int> getDailySrsCount() async {
    getDailySrsCountCalls++;
    return _onGetDailySrsCount();
  }

  @override
  Future<void> loadQuiz({int count = 10}) async {
    resetMastery();
    if (_reviewQuestions.isNotEmpty) {
      currentQuestion = _reviewQuestions.first;
    } else {
      currentQuestion = null;
    }
    // Defer notification to avoid setState() during build
    await Future<void>.delayed(Duration.zero);
    notifyListeners();
  }

  @override
  Future<int> getPendingAnswersCount() async {
    return pendingAnswersCount;
  }

  @override
  Future<int> getPendingSrsUpdatesCount() async {
    return 0;
  }

  @override
  Future<void> syncOfflineData() async {
    // no-op in tests
  }

  @override
  int get totalQuestions => _quizQuestions.length;

  @override
  int get currentQuestionNumber => _questionNumber;

  @override
  Future<bool> startQuiz(int subtopicId, int count) async {
    resetMastery();
    _questionNumber = 1;
    if (_quizQuestions.isNotEmpty) {
      currentQuestion = _quizQuestions.first;
    } else {
      currentQuestion = Question(
        id: 1,
        text: '2 + 2 = ?',
        correctAnswerId: 1,
        options: [
          Option(id: 1, text: '4'),
          Option(id: 2, text: '3'),
        ],
      );
    }
    // Defer notification to avoid setState() during build
    await Future<void>.delayed(Duration.zero);
    notifyListeners();
    return true;
  }
}

class TestLeaderboardProvider extends LeaderboardProvider {
  TestLeaderboardProvider({
    this.globalItems = const [],
    this.friendsItems = const [],
    this.schoolItems = const [],
    this.rivalsItems = const [],
    this.globalMe,
    this.friendsMe,
  }) {
    _setScope(
      LeaderboardScope.global,
      globalItems,
      me: globalMe,
      hasMore: false,
    );
    _setScope(
      LeaderboardScope.friends,
      friendsItems,
      me: friendsMe,
      hasMore: false,
    );
    _setSchools();
    _setRivals();
  }

  final List<LeaderboardItem> globalItems;
  final List<LeaderboardItem> friendsItems;
  @override
  final List<SchoolLeaderboardEntry> schoolItems;
  final List<RivalLeaderboardEntry> rivalsItems;
  final LeaderboardMe? globalMe;
  final LeaderboardMe? friendsMe;

  int loadGlobalCalls = 0;
  int loadFriendsCalls = 0;
  int reloadScopeCalls = 0;
  int reloadSchoolsCalls = 0;
  int fetchRivalsCalls = 0;
  LeaderboardScope? lastReloadScope;
  LeaderboardPeriod? lastReloadPeriod;
  LeaderboardPeriod? lastGlobalPeriod;
  LeaderboardPeriod? lastFriendsPeriod;

  void _setScope(
    LeaderboardScope scope,
    List<LeaderboardItem> items, {
    LeaderboardMe? me,
    required bool hasMore,
  }) {
    final p = pagingFor(scope);
    p.reset();
    p.items.addAll(items);
    p.hasLoadedOnce = true;
    p.hasMore = hasMore;
    // We can't access provider's private _me map, but UI reads through meFor(),
    // which in tests will be served by our override.
    _meOverrides[scope] = me;
  }

  final Map<LeaderboardScope, LeaderboardMe?> _meOverrides = {};

  @override
  LeaderboardMe? meFor(LeaderboardScope scope) => _meOverrides[scope];

  @override
  List<RivalLeaderboardEntry> get rivals => List.unmodifiable(rivalsItems);

  @override
  bool get isLoadingRivals => false;

  @override
  Object? get rivalsError => null;

  @override
  SchoolLeaderboardEntry? get currentSchoolEntry =>
      schoolItems.isEmpty ? null : schoolItems.first;

  @override
  Future<void> loadGlobal([LeaderboardPeriod? period]) async {
    loadGlobalCalls++;
    lastGlobalPeriod = period ?? currentPeriod;
    _setScope(
      LeaderboardScope.global,
      globalItems,
      me: globalMe,
      hasMore: false,
    );
    notifyListeners();
  }

  @override
  Future<void> loadFriends([LeaderboardPeriod? period]) async {
    loadFriendsCalls++;
    lastFriendsPeriod = period ?? currentPeriod;
    _setScope(
      LeaderboardScope.friends,
      friendsItems,
      me: friendsMe,
      hasMore: false,
    );
    notifyListeners();
  }

  @override
  Future<void> reloadScope(
    LeaderboardScope scope, {
    LeaderboardPeriod? period,
  }) async {
    reloadScopeCalls++;
    lastReloadScope = scope;
    lastReloadPeriod = period ?? currentPeriod;
    switch (scope) {
      case LeaderboardScope.global:
        _setScope(scope, globalItems, me: globalMe, hasMore: false);
        break;
      case LeaderboardScope.friends:
        _setScope(scope, friendsItems, me: friendsMe, hasMore: false);
        break;
      default:
        _setScope(scope, const [], me: null, hasMore: false);
        break;
    }
    notifyListeners();
  }

  @override
  Future<void> ensureUsersLoaded() async {
    await reloadScope(LeaderboardScope.global, period: currentPeriod);
    await fetchRivals(period: currentPeriod);
  }

  @override
  Future<void> reloadSchoolLeaderboard({LeaderboardPeriod? period}) async {
    reloadSchoolsCalls++;
    _setSchools();
    notifyListeners();
  }

  @override
  Future<void> ensureSchoolsLoaded() async {
    await reloadSchoolLeaderboard(period: currentPeriod);
  }

  @override
  Future<void> fetchRivals({LeaderboardPeriod? period}) async {
    fetchRivalsCalls++;
    _setRivals();
    notifyListeners();
  }

  void _setSchools() {
    schoolPaging.reset();
    schoolPaging.items.addAll(schoolItems);
    schoolPaging.hasLoadedOnce = true;
    schoolPaging.hasMore = false;
  }

  void _setRivals() {
    // Getter override serves rivals data for widget tests.
  }
}
