import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mathlearning/models/hint_models.dart';
import 'package:mathlearning/models/option.dart';
import 'package:mathlearning/models/question.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/coin_provider.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';

class TestAuthProvider extends ChangeNotifier implements AuthProvider {
  bool _isLoading;
  String? _error;
  bool _isAuthenticated;
  String? _token;
  String? _userId;
  String? _username;

  TestAuthProvider({
    bool isLoading = false,
    bool isAuthenticated = true,
    String? token = 'demo_token_test',
    String? userId = '1',
    String? username = 'Alex',
    String? error,
  }) : _isLoading = isLoading,
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
    notifyListeners();
    return _isAuthenticated;
  }

  @override
  Future<bool> login(String username, String password) async {
    _isAuthenticated = true;
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
    _token = null;
    _userId = null;
    _username = null;
    notifyListeners();
  }
}

class TestCoinProvider extends ChangeNotifier implements CoinProvider {
  int _coins;
  UserDailyHints? _dailyHints;
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
    notifyListeners();
    return true;
  }
}

class TestLeaderboardProvider extends LeaderboardProvider {
  TestLeaderboardProvider({
    this.globalItems = const [],
    this.friendsItems = const [],
    this.myGlobal,
    this.myFriends,
  });

  final List<LeaderboardEntry> globalItems;
  final List<LeaderboardEntry> friendsItems;
  final LeaderboardEntry? myGlobal;
  final LeaderboardEntry? myFriends;

  int loadGlobalCalls = 0;
  int loadFriendsCalls = 0;
  String? lastGlobalRange;
  String? lastFriendsRange;

  @override
  Future<void> loadGlobal(String range) async {
    loadGlobalCalls++;
    lastGlobalRange = range;
    isLoading = true;
    notifyListeners();

    await Future<void>.delayed(Duration.zero);
    global = List<LeaderboardEntry>.from(globalItems);
    myGlobalRank = myGlobal;
    isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> loadFriends(String range) async {
    loadFriendsCalls++;
    lastFriendsRange = range;
    isLoading = true;
    notifyListeners();

    await Future<void>.delayed(Duration.zero);
    friends = List<LeaderboardEntry>.from(friendsItems);
    myFriendsRank = myFriends;
    isLoading = false;
    notifyListeners();
  }
}
