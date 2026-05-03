import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/features/adaptive_practice/models/practice_answer_request.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_answer_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_difficulty.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_question.dart';
import 'package:mathlearning/features/adaptive_practice/models/practice_start_request.dart';
import 'package:mathlearning/features/adaptive_practice/services/practice_session_api_service.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/services/analytics/adaptive_analytics_service.dart';
import 'package:mathlearning/services/connectivity_service.dart';

class AdaptivePracticeProvider extends ChangeNotifier {
  AdaptivePracticeProvider({
    required PracticeSessionApiService apiService,
    required AdaptiveLearningMapRefresher learningMapRefresher,
    Future<void> Function(String childId)? refreshParentDashboard,
  }) : _apiService = apiService,
       _learningMapRefresher = learningMapRefresher,
       _refreshParentDashboard = refreshParentDashboard;

  static const _historyKeyPrefix = 'adaptive_practice.history.v1.';

  final PracticeSessionApiService _apiService;
  final AdaptiveLearningMapRefresher _learningMapRefresher;
  final Future<void> Function(String childId)? _refreshParentDashboard;

  String? _sessionId;
  PracticeQuestion? _currentQuestion;
  int _questionIndex = 0;
  int _targetQuestions = 0;
  int _correctCount = 0;
  int _totalXp = 0;
  double _masteryBefore = 0;
  double _masteryAfter = 0;
  double _initialMastery = 0;
  PracticeDifficulty _difficulty = PracticeDifficulty.unknown;
  bool _loading = false;
  bool _submitting = false;
  String? _error;
  DateTime? _questionShownAt;
  DateTime? _rateLimitUntil;
  Duration _retryCountdown = Duration.zero;
  Timer? _retryTimer;
  PracticeLaunchPlan? _plan;
  PracticeAnswerResponse? _lastAnswerResponse;
  PracticeCompleteResponse? _completion;

  String? get sessionId => _sessionId;
  PracticeQuestion? get currentQuestion => _currentQuestion;
  int get questionIndex => _questionIndex;
  int get targetQuestions => _targetQuestions;
  int get correctCount => _correctCount;
  int get totalXp => _totalXp;
  double get masteryBefore => _masteryBefore;
  double get masteryAfter => _masteryAfter;
  PracticeDifficulty get difficulty => _difficulty;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get error => _error;
  DateTime? get questionShownAt => _questionShownAt;
  PracticeAnswerResponse? get lastAnswerResponse => _lastAnswerResponse;
  PracticeCompleteResponse? get completion => _completion;
  bool get isComplete => _completion != null;
  Duration get retryCountdown => _retryCountdown;
  bool get isRateLimited =>
      _rateLimitUntil != null && _retryCountdown > Duration.zero;

  double get progress {
    if (_targetQuestions <= 0) {
      return 0;
    }
    return (_questionIndex / _targetQuestions).clamp(0.0, 1.0);
  }

  double get accuracy {
    final answered = math.max(1, _questionIndex);
    return (_correctCount / answered).clamp(0.0, 1.0);
  }

  Future<void> start(PracticeLaunchPlan plan) async {
    if (_loading) {
      return;
    }
    _plan = plan;
    _loading = true;
    _error = null;
    _completion = null;
    _lastAnswerResponse = null;
    notifyListeners();

    if (!ConnectivityService.instance.isOnline) {
      _loading = false;
      _error = 'You need Wi\u2011Fi or data to start a practice round!';
      notifyListeners();
      return;
    }

    final request = PracticeStartRequest(
      skillNodeId: plan.nodeId,
      topicId: plan.topicId,
      subtopicId: plan.subtopicId,
      targetQuestions: plan.targetQuestions,
      preferredDifficulty: _mapDifficultyFromLaunch(plan.difficulty),
    );

    final result = await _apiService.startSession(request);
    if (result.data == null || result.error != null) {
      _loading = false;
      _applyRateLimit(
        result.retryAfter,
        defaultMessage:
            result.error?.message ?? 'Something went wrong — tap Try again to keep going!',
      );
      notifyListeners();
      return;
    }

    final response = result.data!;
    _sessionId = response.sessionId;
    _targetQuestions = plan.targetQuestions;
    _questionIndex = 0;
    _correctCount = 0;
    _totalXp = 0;
    _initialMastery = response.initialMastery;
    _masteryBefore = response.initialMastery;
    _masteryAfter = response.initialMastery;
    _difficulty = response.recommendedDifficulty;
    _currentQuestion = response.question;
    _questionShownAt = DateTime.now();
    _loading = false;
    _error = null;
    notifyListeners();
  }

  Future<PracticeAnswerResponse?> answer(String selectedOption) async {
    if (_submitting || _loading || isRateLimited) {
      return null;
    }
    final session = _sessionId;
    final question = _currentQuestion;
    if (session == null || question == null) {
      return null;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    final shownAt = _questionShownAt ?? DateTime.now();
    final timeSpent = DateTime.now().difference(shownAt).inMilliseconds;
    final request = PracticeAnswerRequest(
      questionId: question.id,
      selectedOption: selectedOption,
      timeSpentMs: timeSpent.clamp(100, 180000),
    );

    final result = await _apiService.submitAnswer(session, request);
    if (result.data == null || result.error != null) {
      _submitting = false;
      _applyRateLimit(
        result.retryAfter,
        defaultMessage: result.error?.message ?? 'Unable to submit answer.',
      );
      notifyListeners();
      return null;
    }

    final response = result.data!;
    _lastAnswerResponse = response;
    _questionIndex += 1;
    if (response.isCorrect) {
      _correctCount += 1;
    }
    _totalXp += response.xpEarned;
    _masteryBefore = response.masteryBefore;
    _masteryAfter = response.masteryAfter;
    _currentQuestion = response.nextQuestion;
    _questionShownAt = response.nextQuestion == null ? null : DateTime.now();
    _submitting = false;
    notifyListeners();

    if (!_hasMoreQuestions(response)) {
      await complete();
    }

    return response;
  }

  Future<PracticeCompleteResponse?> complete() async {
    if (_loading) {
      return _completion;
    }
    final session = _sessionId;
    final plan = _plan;
    if (session == null || plan == null) {
      return _completion;
    }

    _loading = true;
    notifyListeners();

    final result = await _apiService.completeSession(session);
    _loading = false;

    if (result.data == null || result.error != null) {
      _applyRateLimit(
        result.retryAfter,
        defaultMessage: result.error?.message ?? 'Unable to complete session.',
      );
      notifyListeners();
      return null;
    }

    _completion = result.data!;
    _totalXp = _completion?.xpEarned ?? _totalXp;
    _masteryBefore = _completion?.initialMastery ?? _initialMastery;
    _masteryAfter = _completion?.finalMastery ?? _masteryAfter;
    _error = null;

    await _saveCompletionHistory(plan.userId, _completion!);
    await _syncDependentProviders(plan, _completion!);

    AdaptiveAnalyticsService.instance
        .logEvent(AdaptiveAnalyticsService.adaptiveSessionCompleted, {
          'sessionId': _completion!.sessionId,
          'accuracy': _completion!.accuracy,
          'xpEarned': _completion!.xpEarned,
        });

    notifyListeners();
    return _completion;
  }

  void reset() {
    _cancelRetryTimer();
    _sessionId = null;
    _currentQuestion = null;
    _questionIndex = 0;
    _targetQuestions = 0;
    _correctCount = 0;
    _totalXp = 0;
    _masteryBefore = 0;
    _masteryAfter = 0;
    _initialMastery = 0;
    _difficulty = PracticeDifficulty.unknown;
    _loading = false;
    _submitting = false;
    _error = null;
    _questionShownAt = null;
    _rateLimitUntil = null;
    _retryCountdown = Duration.zero;
    _plan = null;
    _lastAnswerResponse = null;
    _completion = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelRetryTimer();
    super.dispose();
  }

  bool _hasMoreQuestions(PracticeAnswerResponse response) {
    return response.hasNextQuestion;
  }

  PracticeDifficulty _mapDifficultyFromLaunch(dynamic difficulty) {
    final value = difficulty?.toString().toLowerCase() ?? '';
    switch (value) {
      case 'easy':
      case 'practicedifficulty.easy':
      case 'skilldifficulty.easy':
        return PracticeDifficulty.easy;
      case 'hard':
      case 'practicedifficulty.hard':
      case 'skilldifficulty.hard':
        return PracticeDifficulty.hard;
      case 'medium':
      case 'practicedifficulty.medium':
      case 'skilldifficulty.medium':
      default:
        return PracticeDifficulty.medium;
    }
  }

  void _applyRateLimit(Duration? retryAfter, {required String defaultMessage}) {
    _error = defaultMessage;
    final wait = retryAfter;
    if (wait == null || wait <= Duration.zero) {
      _rateLimitUntil = null;
      _retryCountdown = Duration.zero;
      _cancelRetryTimer();
      return;
    }

    _rateLimitUntil = DateTime.now().add(wait);
    _retryCountdown = wait;
    _startRetryTicker();
  }

  void _startRetryTicker() {
    _cancelRetryTimer();
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final until = _rateLimitUntil;
      if (until == null) {
        timer.cancel();
        return;
      }

      final remaining = until.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _retryCountdown = Duration.zero;
        _rateLimitUntil = null;
        timer.cancel();
      } else {
        _retryCountdown = remaining;
      }
      notifyListeners();
    });
  }

  void _cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Future<void> _syncDependentProviders(
    PracticeLaunchPlan plan,
    PracticeCompleteResponse completion,
  ) async {
    await _learningMapRefresher.completePractice(
      plan: plan,
      xpEarned: completion.xpEarned,
      masteryDelta: completion.masteryDelta,
      accuracy: completion.accuracy,
      recommendedNextNodeId: completion.recommendedNextSkillNodeId,
    );
    await _learningMapRefresher.refresh(plan.userId);

    final refreshParentDashboard = _refreshParentDashboard;
    if (refreshParentDashboard != null) {
      await refreshParentDashboard(plan.userId);
    }
  }

  Future<void> _saveCompletionHistory(
    String userId,
    PracticeCompleteResponse completion,
  ) async {
    if (userId.isEmpty) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = '$_historyKeyPrefix$userId';
    final raw = prefs.getString(key);
    final parsed = raw == null ? <Map<String, dynamic>>[] : _parseHistory(raw);
    final entry = completion.toJson()
      ..['savedAt'] = DateTime.now().toUtc().toIso8601String();
    parsed.insert(0, entry);
    final capped = parsed.take(20).toList(growable: false);
    await prefs.setString(key, jsonEncode(capped));
  }

  List<Map<String, dynamic>> _parseHistory(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}

abstract class AdaptiveLearningMapRefresher {
  Future<void> completePractice({
    required PracticeLaunchPlan plan,
    required int xpEarned,
    required double masteryDelta,
    required double accuracy,
    required String? recommendedNextNodeId,
  });

  Future<void> refresh(String userId);
}

class LearningMapRefresherAdapter implements AdaptiveLearningMapRefresher {
  LearningMapRefresherAdapter(this._learningMapProvider);

  final LearningMapProvider _learningMapProvider;

  @override
  Future<void> completePractice({
    required PracticeLaunchPlan plan,
    required int xpEarned,
    required double masteryDelta,
    required double accuracy,
    required String? recommendedNextNodeId,
  }) {
    return _learningMapProvider.completePractice(
      plan: plan,
      xpEarned: xpEarned,
      masteryDelta: masteryDelta,
      accuracy: accuracy,
      recommendedNextNodeId: recommendedNextNodeId,
    );
  }

  @override
  Future<void> refresh(String userId) {
    return _learningMapProvider.refresh(userId);
  }
}
