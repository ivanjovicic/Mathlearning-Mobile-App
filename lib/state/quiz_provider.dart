import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/offline_manager.dart';
import '../services/srs_service.dart';
import '../models/question.dart';
import '../models/option.dart';
import '../models/hint_models.dart';
import '../models/step_explanation.dart';
import '../navigation/navigation_extensions.dart';
import '../screens/quiz_summary_screen.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/formula_hint_bottom_sheet.dart';
import 'progress_provider.dart';
import 'coin_provider.dart';
import 'settings_provider.dart';

class QuizProvider extends ChangeNotifier {
  static const int _baseXpReward = 20;
  static const int _noHintBonusXp = 5;
  static const Duration _dailySrsCacheTtl = Duration(seconds: 20);

  final api = ApiService();
  final _offline = OfflineManager.instance;
  final _srs = SrsService.instance;

  /// Injected by ProxyProvider — used for optimistic XP/streak updates.
  ProgressProvider? _progress;

  /// Called by ProxyProvider on update to inject latest ProgressProvider.
  void updateProgressProvider(ProgressProvider progress) {
    _progress = progress;
  }

  String? token;
  String? quizId;
  Question? currentQuestion;
  int questionsAnsweredInSession = 0;
  List<Question> _allQuestions = []; // Store all questions for offline mode
  int _currentQuestionIndex = 0;
  bool _isSrsMode = false; // Track if current quiz is SRS mode
  int _questionStartTime =
      0; // Track when question started for time calculation
  bool _isSubmittingAnswer = false;
  List<Map<String, dynamic>>? _cachedDailySrsQuestions;
  DateTime? _cachedDailySrsAt;
  Future<List<Map<String, dynamic>>>? _dailySrsFetchInFlight;

  // Hint system state
  String? _currentClue;
  List<String> _eliminatedOptions = [];
  bool _isLoadingHint = false;
  bool _usedHintForCurrentQuestion = false;

  // Cooldown system state
  bool _isCooldown = false;

  bool get isOnline => _offline.isOnline;
  String? get currentClue => _currentClue;
  List<String> get eliminatedOptions => _eliminatedOptions;
  bool get isLoadingHint => _isLoadingHint;
  bool get usedHintForCurrentQuestion => _usedHintForCurrentQuestion;
  bool get isCooldown => _isCooldown;
  bool get isSrsMode => _isSrsMode;
  bool get isSubmittingAnswer => _isSubmittingAnswer;
  int get totalQuestions => _allQuestions.length;
  int get currentQuestionNumber => _currentQuestionIndex + 1;
  List<Question> get questions => List.unmodifiable(_allQuestions);
  List<StepExplanation> _currentSteps = [];
  List<StepExplanation> get currentSteps => List.unmodifiable(_currentSteps);
  double _masteryPercent = 0.0;
  double get masteryPercent => _masteryPercent;

  // Session stats for summary screen
  int _correctCount = 0;
  int _sessionXp = 0;
  int? _sessionStartTotalXp;
  final List<WrongQuestion> _wrongQuestions = [];
  final Set<int> _rewardedQuestionIds = <int>{};
  final Set<String> _awardedQuestionFingerprints = <String>{};

  int get correctCount => _correctCount;
  int get sessionXp => _sessionXp;
  List<WrongQuestion> get wrongQuestions => List.unmodifiable(_wrongQuestions);
  bool get alreadyAwardedForCurrentQuestion {
    final q = currentQuestion;
    if (q == null) return false;
    return _rewardedQuestionIds.contains(q.id) ||
        _awardedQuestionFingerprints.contains(_questionFingerprint(q));
  }

  bool canAwardXpForQuestion(Question question) {
    return !_rewardedQuestionIds.contains(question.id) &&
        !_awardedQuestionFingerprints.contains(_questionFingerprint(question));
  }

  void markHintUsedForCurrentQuestion() {
    if (_usedHintForCurrentQuestion) return;
    _usedHintForCurrentQuestion = true;
    notifyListeners();
  }

  void resetAwardHistory() {
    _rewardedQuestionIds.clear();
    _awardedQuestionFingerprints.clear();
    notifyListeners();
  }

  bool _skipDailyReviewOnce = false;

  void skipDailyReviewOnce() {
    _skipDailyReviewOnce = true;
  }

  bool consumeSkipDailyReviewOnce() {
    final shouldSkip = _skipDailyReviewOnce;
    _skipDailyReviewOnce = false;
    return shouldSkip;
  }

  void resetMastery() {
    _masteryPercent = 0.0;
  }

  void setSteps(List<StepExplanation> steps, {bool notify = true}) {
    _currentSteps = List<StepExplanation>.from(steps);
    if (notify) {
      notifyListeners();
    }
  }

  void _syncStepsFromCurrentQuestion({bool notify = false}) {
    setSteps(currentQuestion?.steps ?? const [], notify: notify);
  }

  void applyMasteryDelta({required bool isCorrect}) {
    final delta = isCorrect ? 0.12 : -0.06;
    _masteryPercent = (_masteryPercent + delta).clamp(0.0, 1.0);
    notifyListeners();
  }

  Future<void> loadQuiz({int count = 10}) async {
    questionsAnsweredInSession = 0;
    _currentQuestionIndex = 0;
    _allQuestions = [];
    _isSrsMode = true;
    _correctCount = 0;
    _sessionXp = 0;
    _sessionStartTotalXp = _currentProgressTotalXp();
    _wrongQuestions.clear();
    _resetHints();
    resetMastery();

    final srsQuestions = await _fetchDailySrsQuestions();
    final limited = srsQuestions.take(count);
    _allQuestions = limited.map((q) => Question.fromJson(q)).toList();
    _allQuestions = _dedupeQuestionsByContent(_allQuestions);

    if (_allQuestions.isNotEmpty) {
      quizId = "srs-review-${DateTime.now().millisecondsSinceEpoch}";
      currentQuestion = _allQuestions[0];
      _syncStepsFromCurrentQuestion();
      _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    } else {
      quizId = null;
      currentQuestion = null;
      _syncStepsFromCurrentQuestion();
    }

    notifyListeners();
  }

  Future<int> getDailySrsCount() async {
    final srsQuestions = await _fetchDailySrsQuestions();
    return srsQuestions.length;
  }

  Future<bool> startQuiz(int subtopicId, int count) async {
    try {
      // Reset quiz state
      questionsAnsweredInSession = 0;
      _currentQuestionIndex = 0;
      _allQuestions = [];
      _isSrsMode = false;
      _correctCount = 0;
      _sessionXp = 0;
      _sessionStartTotalXp = _currentProgressTotalXp();
      _wrongQuestions.clear();
      _resetHints();
      resetMastery();

      // 1ï¸âƒ£ FIRST: Try to get SRS questions (priority)
      final srsQuestions = await _fetchDailySrsQuestions();

      if (srsQuestions.isNotEmpty) {
        debugPrint('âœ… Found ${srsQuestions.length} SRS questions for review');
        _allQuestions = srsQuestions.map((q) => Question.fromJson(q)).toList();
        _allQuestions = _dedupeQuestionsByContent(_allQuestions);
        _isSrsMode = true;
        quizId = "srs-quiz-${DateTime.now().millisecondsSinceEpoch}";
        currentQuestion = _allQuestions[0];
        _syncStepsFromCurrentQuestion();
        _questionStartTime = DateTime.now().millisecondsSinceEpoch;
        notifyListeners();
        return true;
      }

      // 2ï¸âƒ£ FALLBACK: Try to get normal topic questions
      final questionsData = await _offline.getQuestions(
        subtopicId,
        count,
        token,
      );

      if (questionsData != null && questionsData.isNotEmpty) {
        // Convert to Question objects
        _allQuestions = questionsData.map((q) => Question.fromJson(q)).toList();
        _allQuestions = _dedupeQuestionsByContent(_allQuestions);

        // Generate quiz ID
        quizId = "quiz-${DateTime.now().millisecondsSinceEpoch}";

        // Set first question
        currentQuestion = _allQuestions[0];
        _syncStepsFromCurrentQuestion();
        _questionStartTime = DateTime.now().millisecondsSinceEpoch;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Start quiz failed: $e');
    }

    // Use fallback questions for demo mode
    return await _startFallbackQuiz();
  }

  Future<List<Map<String, dynamic>>> _fetchDailySrsQuestions({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final hasFreshCache =
        !forceRefresh &&
        _cachedDailySrsQuestions != null &&
        _cachedDailySrsAt != null &&
        now.difference(_cachedDailySrsAt!) < _dailySrsCacheTtl;

    if (hasFreshCache) {
      return List<Map<String, dynamic>>.from(_cachedDailySrsQuestions!);
    }

    if (_dailySrsFetchInFlight != null) {
      return _dailySrsFetchInFlight!;
    }

    final task = _srs
        .fetchDailySrsQuestions()
        .then((questions) {
          final copy = List<Map<String, dynamic>>.from(questions);
          _cachedDailySrsQuestions = copy;
          _cachedDailySrsAt = DateTime.now();
          return copy;
        })
        .whenComplete(() {
          _dailySrsFetchInFlight = null;
        });

    _dailySrsFetchInFlight = task;
    return task;
  }

  Future<bool> _startFallbackQuiz() async {
    // Demo quiz for offline use with multiple questions
    quizId = "demo-quiz-${DateTime.now().millisecondsSinceEpoch}";
    resetMastery();

    _allQuestions = [
      Question(
        id: 1,
        text: "Koliko je 2 + 2?",
        correctAnswerId: 1,
        options: [
          Option(id: 1, text: "4"),
          Option(id: 2, text: "3"),
          Option(id: 3, text: "5"),
          Option(id: 4, text: "6"),
        ],
      ),
      Question(
        id: 2,
        text: "Koliko je 5 Ã— 3?",
        correctAnswerId: 5,
        options: [
          Option(id: 5, text: "15"),
          Option(id: 6, text: "12"),
          Option(id: 7, text: "18"),
          Option(id: 8, text: "20"),
        ],
      ),
      Question(
        id: 3,
        text: "Koliko je 10 Ã· 2?",
        correctAnswerId: 9,
        options: [
          Option(id: 9, text: "5"),
          Option(id: 10, text: "4"),
          Option(id: 11, text: "6"),
          Option(id: 12, text: "3"),
        ],
      ),
      Question(
        id: 4,
        text: "Koliko je 8 - 3?",
        correctAnswerId: 13,
        options: [
          Option(id: 13, text: "5"),
          Option(id: 14, text: "4"),
          Option(id: 15, text: "6"),
          Option(id: 16, text: "7"),
        ],
      ),
      Question(
        id: 5,
        text: "Koliko je 6 + 7?",
        correctAnswerId: 17,
        options: [
          Option(id: 17, text: "13"),
          Option(id: 18, text: "12"),
          Option(id: 19, text: "14"),
          Option(id: 20, text: "15"),
        ],
      ),
      // Plain sentence (tests regular text rendering and spacing).
      Question(
        id: 6,
        text: "What is the perimeter of a triangle with sides 3, 4, and 5?",
        correctAnswerId: 101,
        options: [
          Option(id: 101, text: "12"),
          Option(id: 102, text: "10"),
          Option(id: 103, text: "11"),
          Option(id: 104, text: "13"),
        ],
        hintLight: "Perimeter is the sum of all side lengths.",
        hintMedium: "Add all three sides: 3 + 4 + 5.",
        hintFull: "3 + 4 + 5 = 12",
        explanation:
            "Perimeter = a + b + c\nPerimeter = 3 + 4 + 5\nPerimeter = 12",
      ),
      // Fraction LaTeX.
      Question(
        id: 7,
        text: r"\frac{3}{4} + \frac{1}{4} = ?",
        correctAnswerId: 201,
        options: [
          Option(id: 201, text: "1"),
          Option(id: 202, text: r"\frac{1}{2}"),
          Option(id: 203, text: r"\frac{3}{2}"),
          Option(id: 204, text: "2"),
        ],
      ),
      // Radical.
      Question(
        id: 8,
        text: r"\sqrt{49} = ?",
        correctAnswerId: 301,
        options: [
          Option(id: 301, text: "7"),
          Option(id: 302, text: "14"),
          Option(id: 303, text: "6"),
          Option(id: 304, text: "8"),
        ],
      ),
      // Exponent.
      Question(
        id: 9,
        text: "2^5 = ?",
        correctAnswerId: 401,
        options: [
          Option(id: 401, text: "32"),
          Option(id: 402, text: "16"),
          Option(id: 403, text: "64"),
          Option(id: 404, text: "25"),
        ],
      ),
      // Plain text linear equation.
      Question(
        id: 10,
        text: "Solve the equation: 3x + 2 = 11. What is x?",
        correctAnswerId: 501,
        options: [
          Option(id: 501, text: "3"),
          Option(id: 502, text: "2"),
          Option(id: 503, text: "4"),
          Option(id: 504, text: "5"),
        ],
        hintLight: "Isolate x.",
        hintMedium: "Subtract 2 from both sides first.",
        hintFull: "3x + 2 = 11 => 3x = 9 => x = 3",
      ),
      // Trigonometric LaTeX.
      Question(
        id: 11,
        text: r"\sin\left(\frac{\pi}{2}\right) = ?",
        correctAnswerId: 601,
        options: [
          Option(id: 601, text: "1"),
          Option(id: 602, text: "0"),
          Option(id: 603, text: "-1"),
          Option(id: 604, text: r"\frac{1}{2}"),
        ],
      ),
      // Integral LaTeX.
      Question(
        id: 12,
        text: r"\int_0^2 x \, dx = ?",
        correctAnswerId: 701,
        options: [
          Option(id: 701, text: "2"),
          Option(id: 702, text: "1"),
          Option(id: 703, text: "4"),
          Option(id: 704, text: "0"),
        ],
      ),
      // Probability sentence.
      Question(
        id: 13,
        text: "A fair coin is tossed once. What is the probability of heads?",
        correctAnswerId: 801,
        options: [
          Option(id: 801, text: "1/2"),
          Option(id: 802, text: "1/3"),
          Option(id: 803, text: "1/4"),
          Option(id: 804, text: "2/3"),
        ],
      ),
    ];

    _currentQuestionIndex = 0;
    currentQuestion = _allQuestions[0];
    _syncStepsFromCurrentQuestion();
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    _sessionStartTotalXp = _currentProgressTotalXp();

    debugPrint('âœ… Demo quiz started with ${_allQuestions.length} questions');
    notifyListeners();
    return true;
  }

  Future<void> answer(String answer, BuildContext context) async {
    if (currentQuestion == null) return;
    if (_isSubmittingAnswer) return;

    _isSubmittingAnswer = true;
    notifyListeners();

    try {
      final selectedOptionId = int.tryParse(answer);

      // Find selected option by ID (preferred) or fallback to option text
      Option? selectedOption;
      for (final option in currentQuestion!.options) {
        if (selectedOptionId != null && option.id == selectedOptionId) {
          selectedOption = option;
          break;
        }
        if (option.text == answer) {
          selectedOption = option;
          break;
        }
      }

      // Calculate if answer is correct by comparing option ID
      bool isCorrect =
          selectedOption != null &&
          selectedOption.id == currentQuestion!.correctAnswerId;

      debugPrint(
        'ðŸŽ¯ Answer: "$answer" (ID: ${selectedOption?.id}) | Correct ID: ${currentQuestion!.correctAnswerId} | Is Correct: $isCorrect',
      );

      // Calculate time spent on this question
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeMs = currentTime - _questionStartTime;
      final localTotalXpBefore = _currentProgressTotalXp();

      final questionFingerprint = _questionFingerprint(currentQuestion!);
      final shouldRewardProgress =
          _rewardedQuestionIds.add(currentQuestion!.id) &&
          _awardedQuestionFingerprints.add(questionFingerprint);
      final fallbackXpForQuestion = isCorrect
          ? _baseXpReward + (_usedHintForCurrentQuestion ? 0 : _noHintBonusXp)
          : 0;
      Map<String, dynamic>? serverResponse;

      try {
        // If this is SRS mode, update SRS data (online or queued offline).
        if (_isSrsMode) {
          await _offline.submitSrsUpdate(
            questionId: currentQuestion!.id,
            isCorrect: isCorrect,
            timeMs: timeMs,
          );
          debugPrint(
            'SRS processed: Q${currentQuestion!.id}, correct=$isCorrect, time=${timeMs}ms',
          );
        }

        // Submit answer (online or queue for offline sync)
        serverResponse = await _offline.submitAnswer(
          quizId: quizId!,
          questionId: currentQuestion!.id,
          answer: selectedOption?.text ?? answer,
          timeSpentSeconds: 3, // Could be calculated dynamically
          isCorrect: isCorrect,
          token: token,
        );
      } on ApiRateLimitedException catch (e) {
        if (context.mounted) {
          final seconds = (e.retryAfter?.inSeconds ?? 1).clamp(1, 60).toInt();
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Server je zauzet (429). Pokusaj za $seconds s. Odgovor je sacuvan offline.',
              ),
              duration: Duration(seconds: seconds < 5 ? 5 : seconds),
            ),
          );
        }
        // Continue: answer is already queued offline by OfflineManager.
      } catch (e) {
        debugPrint('Error submitting answer: $e');
        // Continue anyway - answer is saved for sync
      }

      var effectiveXpForQuestion = fallbackXpForQuestion;
      if (serverResponse != null) {
        final serverAwardedXp = _readIntFromResponse(serverResponse, const [
          'awardedXp',
          'awardedXP',
          'xpAwarded',
          'earnedXp',
          'earnedXP',
        ]);
        final serverIsFirstTimeCorrect = _readBoolFromResponse(
          serverResponse,
          const [
            'isFirstTimeCorrect',
            'isFirstCorrect',
            'firstTimeCorrect',
            'firstCorrect',
          ],
        );
        final serverTotalXp = _readIntFromResponse(serverResponse, const [
          'totalXp',
          'totalXP',
          'xpTotal',
          'totalExperience',
        ]);

        final hasReliableServerTotal =
            serverTotalXp != null &&
            localTotalXpBefore != null &&
            serverTotalXp >= localTotalXpBefore;
        final hasPositiveServerAward =
            serverAwardedXp != null && serverAwardedXp > 0;
        final canTrustFirstTimeFlag =
            hasReliableServerTotal || hasPositiveServerAward;

        if (canTrustFirstTimeFlag && serverIsFirstTimeCorrect == false) {
          effectiveXpForQuestion = 0;
        } else if (hasReliableServerTotal) {
          // Prefer server absolute total XP when available.
          final delta = serverTotalXp - localTotalXpBefore;
          effectiveXpForQuestion = delta > 0 ? delta : 0;
        } else if (hasPositiveServerAward) {
          effectiveXpForQuestion = serverAwardedXp;
        }
      }

      if (shouldRewardProgress) {
        _progress?.applyAnswerResult(
          isCorrect: isCorrect,
          xpForQuestion: isCorrect ? effectiveXpForQuestion : 0,
        );
        await _progress?.persistLocalProgress();
        if (isCorrect && effectiveXpForQuestion > 0) {
          _sessionXp += effectiveXpForQuestion;
        }
      } else {
        debugPrint(
          'Skipping duplicate XP reward for questionId=${currentQuestion!.id}, fingerprint=$questionFingerprint',
        );
      }

      questionsAnsweredInSession++;

      // Track session stats
      if (isCorrect) {
        _correctCount++;
      } else {
        // Find correct answer text
        final correctOption = currentQuestion!.options.firstWhere(
          (o) => o.id == currentQuestion!.correctAnswerId,
          orElse: () => currentQuestion!.options.first,
        );
        _wrongQuestions.add(
          WrongQuestion(
            questionId: currentQuestion!.id,
            questionText: currentQuestion!.text,
            userAnswer: selectedOption?.text ?? answer,
            correctAnswer: correctOption.text,
          ),
        );
      }

      // Check if quiz is finished
      if (questionsAnsweredInSession >= _allQuestions.length) {
        // Quiz completed - show results
        if (!context.mounted) return;
        await _handleQuizCompletion(context);
        return;
      }

      // Move to next question with cooldown
      _isCooldown = true;
      notifyListeners();
    } finally {
      _isSubmittingAnswer = false;
      notifyListeners();
    }
  }

  Future<void> goToNextQuestion() async {
    _currentQuestionIndex++;
    if (_currentQuestionIndex < _allQuestions.length) {
      currentQuestion = _allQuestions[_currentQuestionIndex];
      _syncStepsFromCurrentQuestion();
      _resetHints(); // Reset hints for new question
      _questionStartTime =
          DateTime.now().millisecondsSinceEpoch; // Reset timer for new question
    }
    _isCooldown = false;
    notifyListeners();
  }

  Future<void> _handleQuizCompletion(BuildContext context) async {
    // REFRESH XP + LEVEL immediately after quiz completion
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final oldLevel = progress.level;
    final oldAccuracy = progress.accuracy;
    // Keep optimistic XP/streak and attempt best-effort sync.
    // Using loadProgress here can overwrite fresh local progress with stale
    // server data right after quiz completion.
    await progress.syncWithServer();
    await progress.persistLocalProgress();
    await progress.loadTopics();
    if (!context.mounted) return;

    final totalXpAfterSync =
        ((progress.level - 1) * progress.xpToNextLevel) + progress.xp;
    final xpFromProgressDelta = _sessionStartTotalXp == null
        ? 0
        : (totalXpAfterSync - _sessionStartTotalXp!).clamp(0, 1 << 30);
    final summaryXp = xpFromProgressDelta > _sessionXp
        ? xpFromProgressDelta
        : _sessionXp;

    // Build session stats for summary screen
    final stats = QuizSessionStats(
      correct: _correctCount,
      total: _allQuestions.length,
      xpEarned: summaryXp,
      streak: progress.streak,
      masteryProgress: _masteryPercent,
      wrongQuestions: List.from(_wrongQuestions),
    );

    // Check for level up after progress refresh
    if (progress.level > oldLevel) {
      bool hasAccuracyAchievement = _checkAccuracyAchievement(
        oldAccuracy,
        progress.accuracy,
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: LevelUpAnimation(
            level: progress.level,
            onFinished: () {
              Navigator.pop(context); // Close level-up dialog

              () async {
                if (hasAccuracyAchievement) {
                  await _showAccuracyAchievement(context, progress.accuracy);
                }
                if (!context.mounted) return;
                context.openResults(
                  quizId ?? 'session',
                  source: _isSrsMode ? 'daily_review' : 'quiz',
                  stats: stats,
                );
              }();
            },
          ),
        ),
      );
    } else {
      if (_checkAccuracyAchievement(oldAccuracy, progress.accuracy)) {
        await _showAccuracyAchievement(context, progress.accuracy);
      }
      if (!context.mounted) return;
      context.openResults(
        quizId ?? 'session',
        source: _isSrsMode ? 'daily_review' : 'quiz',
        stats: stats,
      );
    }

    // Reset quiz state
    questionsAnsweredInSession = 0;
    _currentQuestionIndex = 0;
    _allQuestions = [];
    currentQuestion = null;
    _syncStepsFromCurrentQuestion();
    _correctCount = 0;
    _sessionXp = 0;
    _sessionStartTotalXp = null;
    _wrongQuestions.clear();
    notifyListeners();
  }

  List<Question> _dedupeQuestionsByContent(List<Question> questions) {
    final seen = <String>{};
    final unique = <Question>[];

    for (final q in questions) {
      final key = _questionFingerprint(q);
      if (seen.add(key)) {
        unique.add(q);
      }
    }

    if (unique.length != questions.length) {
      debugPrint(
        'Deduped questions by content: ${questions.length - unique.length} removed',
      );
    }
    return unique;
  }

  String _questionFingerprint(Question q) {
    final normalizedQuestion = _normalizeText(q.text);
    final optionTexts = q.options.map((o) => _normalizeText(o.text)).toList()
      ..sort();
    return '$normalizedQuestion|${optionTexts.join('|')}';
  }

  String _normalizeText(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Map<String, dynamic> _flattenResponse(Map<String, dynamic> response) {
    final flat = Map<String, dynamic>.from(response);
    final data = response['data'];
    if (data is Map) {
      for (final entry in data.entries) {
        flat.putIfAbsent(entry.key.toString(), () => entry.value);
      }
    }
    return flat;
  }

  int? _currentProgressTotalXp() {
    final p = _progress;
    if (p == null) return null;
    return ((p.level - 1) * p.xpToNextLevel) + p.xp;
  }

  int? _readIntFromResponse(Map<String, dynamic> response, List<String> keys) {
    final flat = _flattenResponse(response);
    for (final key in keys) {
      if (!flat.containsKey(key)) continue;
      final value = flat[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  bool? _readBoolFromResponse(
    Map<String, dynamic> response,
    List<String> keys,
  ) {
    final flat = _flattenResponse(response);
    for (final key in keys) {
      if (!flat.containsKey(key)) continue;
      final value = flat[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
    }
    return null;
  }

  bool _checkAccuracyAchievement(double oldAccuracy, double newAccuracy) {
    // Check if any accuracy threshold was crossed
    return (oldAccuracy < 90 && newAccuracy >= 90) ||
        (oldAccuracy < 75 && newAccuracy >= 75) ||
        (oldAccuracy < 50 && newAccuracy >= 50);
  }

  Future<void> _showAccuracyAchievement(
    BuildContext context,
    double accuracy,
  ) async {
    String title, subtitle, icon;

    if (accuracy >= 90) {
      title = "Tacnost 90%";
      subtitle = "Vrhunska preciznost";
      icon = "90%";
    } else if (accuracy >= 75) {
      title = "Tacnost 75%";
      subtitle = "Odlican rezultat";
      icon = "75%";
    } else if (accuracy >= 50) {
      title = "Tacnost 50%";
      subtitle = "Polovina pogodaka";
      icon = "50%";
    } else {
      return; // No achievement to show
    }

    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (_) =>
          AchievementPopup(title: title, subtitle: subtitle, icon: icon),
    );
  }

  // Get pending answers count for UI display
  Future<int> getPendingAnswersCount() async {
    return await _offline.getPendingAnswersCount();
  }

  Future<int> getPendingSrsUpdatesCount() async {
    return await _offline.getPendingSrsUpdatesCount();
  }

  // Manual sync trigger
  Future<void> syncOfflineData() async {
    await _offline.syncPendingData();
  }

  // HINT SYSTEM METHODS

  Future<void> showFormulaHint(BuildContext context) async {
    if (currentQuestion == null) return;
    if (!_isHintEnabled(context, HintType.formula)) return;

    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    final inlineSteps = currentQuestion!.steps.isNotEmpty
        ? currentQuestion!.steps
        : _currentSteps;

    // Check if user can afford the hint
    if (!coinProvider.canAffordHint(HintType.formula)) {
      _showInsufficientCoinsDialog(context, HintType.formula);
      return;
    }

    _isLoadingHint = true;
    notifyListeners();

    try {
      if (inlineSteps.isNotEmpty) {
        await coinProvider.useHint(HintType.formula);
        _usedHintForCurrentQuestion = true;
        notifyListeners();

        if (context.mounted) {
          await FormulaHintBottomSheet.showSteps(context, inlineSteps);
        }
        return;
      }

      final formula = await api.fetchFormulaHint(currentQuestion!.id);

      if (formula != null) {
        // Deduct cost
        await coinProvider.useHint(HintType.formula);
        _usedHintForCurrentQuestion = true;
        notifyListeners();

        // Show formula in bottom sheet
        if (context.mounted) {
          await FormulaHintBottomSheet.show(context, formula);
        }
      } else {
        if (context.mounted) {
          _showHintErrorDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error fetching formula hint: $e');
      if (context.mounted) {
        _showHintErrorDialog(context);
      }
    } finally {
      _isLoadingHint = false;
      notifyListeners();
    }
  }

  Future<void> showClueHint(BuildContext context) async {
    if (currentQuestion == null) return;
    if (!_isHintEnabled(context, HintType.clue)) return;

    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    // Check if user can afford the hint
    if (!coinProvider.canAffordHint(HintType.clue)) {
      _showInsufficientCoinsDialog(context, HintType.clue);
      return;
    }

    _isLoadingHint = true;
    notifyListeners();

    try {
      final clue = await api.fetchClueHint(currentQuestion!.id);

      if (clue != null) {
        // Deduct cost
        await coinProvider.useHint(HintType.clue);
        _usedHintForCurrentQuestion = true;

        // Show clue
        _currentClue = clue;
        notifyListeners();

        // Hide clue after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          _currentClue = null;
          notifyListeners();
        });
      } else {
        if (context.mounted) {
          _showHintErrorDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error fetching clue hint: $e');
      if (context.mounted) {
        _showHintErrorDialog(context);
      }
    } finally {
      _isLoadingHint = false;
      notifyListeners();
    }
  }

  Future<void> eliminateWrongOption(BuildContext context) async {
    if (currentQuestion == null) return;
    if (!_isHintEnabled(context, HintType.eliminate)) return;

    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    // Check if user can afford the hint
    if (!coinProvider.canAffordHint(HintType.eliminate)) {
      _showInsufficientCoinsDialog(context, HintType.eliminate);
      return;
    }

    _isLoadingHint = true;
    notifyListeners();

    try {
      final remainingOptions = await api.eliminateOption(currentQuestion!.id);

      if (remainingOptions != null) {
        // Deduct cost
        await coinProvider.useHint(HintType.eliminate);
        _usedHintForCurrentQuestion = true;

        // Backend compatibility:
        // - legacy shape: remaining option IDs
        // - current shape: remaining option texts
        final allOptionIds = currentQuestion!.options
            .map((o) => o.id.toString())
            .toList();
        final remainingSet = remainingOptions.toSet();
        final hasIdPayload = remainingSet.any(allOptionIds.contains);

        if (hasIdPayload) {
          _eliminatedOptions = allOptionIds
              .where((id) => !remainingSet.contains(id))
              .toList();
        } else {
          final allOptionsByText = {
            for (final o in currentQuestion!.options) o.text: o.id.toString(),
          };
          _eliminatedOptions = allOptionsByText.entries
              .where((entry) => !remainingSet.contains(entry.key))
              .map((entry) => entry.value)
              .toList();
        }

        notifyListeners();
      } else {
        if (context.mounted) {
          _showHintErrorDialog(context);
        }
      }
    } catch (e) {
      debugPrint('Error eliminating option: $e');
      if (context.mounted) {
        _showHintErrorDialog(context);
      }
    } finally {
      _isLoadingHint = false;
      notifyListeners();
    }
  }

  void _showInsufficientCoinsDialog(BuildContext context, String hintType) {
    final cost = HintCosts.getCost(hintType);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nedovoljno zlatnika'),
        content: Text(
          'Potrebno je $cost zlatnika za ovu pomoc. Osvoji jos zlatnika kroz kvizove.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  void _showHintErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomoc nije dostupna'),
        content: const Text(
          'Pomoc trenutno nije dostupna. Pokusaj ponovo kasnije.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('U redu'),
          ),
        ],
      ),
    );
  }

  bool _isHintEnabled(BuildContext context, String hintType) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.isHintTypeEnabled(hintType)) {
      return true;
    }
    final parentContext = context;

    final message = !settings.hintsEnabled
        ? 'Hint opcije su trenutno iskljucene u podesavanjima.'
        : 'Ovaj hint je iskljucen u podesavanjima.';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hint je iskljucen'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('U redu'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              parentContext.openSettings();
            },
            child: const Text('Podesavanja'),
          ),
        ],
      ),
    );
    return false;
  }

  // Reset hints when starting new question
  void _resetHints() {
    _currentClue = null;
    _eliminatedOptions = [];
    _isLoadingHint = false;
    _usedHintForCurrentQuestion = false;
  }
}
