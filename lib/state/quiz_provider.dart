import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/offline_manager.dart';
import '../models/question.dart';
import '../models/option.dart';
import '../models/hint_models.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/formula_hint_bottom_sheet.dart';
import 'progress_provider.dart';
import 'coin_provider.dart';
import 'settings_provider.dart';

class QuizProvider extends ChangeNotifier {
  final api = ApiService();
  final _offline = OfflineManager.instance;

  String? token;
  String? quizId;
  Question? currentQuestion;
  int questionsAnsweredInSession = 0;
  List<Question> _allQuestions = []; // Store all questions for offline mode
  int _currentQuestionIndex = 0;

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
  int get totalQuestions => _allQuestions.length;
  int get currentQuestionNumber => _currentQuestionIndex + 1;

  Future<bool> startQuiz(int subtopicId, int count) async {
    try {
      // Reset quiz state
      questionsAnsweredInSession = 0;
      _currentQuestionIndex = 0;
      _allQuestions = [];
      _resetHints();

      // Try to get questions (online first, fallback to cache)
      final questionsData = await _offline.getQuestions(
        subtopicId,
        count,
        token,
      );

      if (questionsData != null && questionsData.isNotEmpty) {
        // Convert to Question objects
        _allQuestions = questionsData.map((q) => Question.fromJson(q)).toList();

        // Generate quiz ID
        quizId = "quiz-${DateTime.now().millisecondsSinceEpoch}";

        // Set first question
        currentQuestion = _allQuestions[0];
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Start quiz failed: $e');
    }

    // Use fallback questions for demo mode
    return await _startFallbackQuiz();
  }

  Future<bool> _startFallbackQuiz() async {
    // Demo quiz for offline use with multiple questions
    quizId = "demo-quiz-${DateTime.now().millisecondsSinceEpoch}";

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
        text: "Koliko je 5 × 3?",
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
        text: "Koliko je 10 ÷ 2?",
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
    ];

    _currentQuestionIndex = 0;
    currentQuestion = _allQuestions[0];

    debugPrint('✅ Demo quiz started with ${_allQuestions.length} questions');
    notifyListeners();
    return true;
  }

  Future<void> answer(String answer, BuildContext context) async {
    if (currentQuestion == null) return;

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
      '🎯 Answer: "$answer" (ID: ${selectedOption?.id}) | Correct ID: ${currentQuestion!.correctAnswerId} | Is Correct: $isCorrect',
    );

    try {
      // Submit answer (online or queue for offline sync)
      await _offline.submitAnswer(
        quizId: quizId!,
        questionId: currentQuestion!.id,
        answer: selectedOption?.text ?? answer,
        timeSpentSeconds: 3, // Could be calculated dynamically
        isCorrect: isCorrect,
        token: token,
      );
    } catch (e) {
      debugPrint('Error submitting answer: $e');
      // Continue anyway - answer is saved for sync
    }

    questionsAnsweredInSession++;

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
  }

  Future<void> goToNextQuestion() async {
    _currentQuestionIndex++;
    if (_currentQuestionIndex < _allQuestions.length) {
      currentQuestion = _allQuestions[_currentQuestionIndex];
      _resetHints(); // Reset hints for new question
    }
    _isCooldown = false;
    notifyListeners();
  }

  Future<void> _handleQuizCompletion(BuildContext context) async {
    // REFRESH XP + LEVEL immediately after quiz completion
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final oldLevel = progress.level;
    final oldAccuracy = progress.accuracy;

    await progress.loadProgress(); // Refresh progress data
    if (!context.mounted) return;

    // Check for level up after progress refresh
    if (progress.level > oldLevel) {
      // Check if there's also an accuracy achievement
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

              // Show accuracy achievement after level-up if applicable
              if (hasAccuracyAchievement) {
                _showAccuracyAchievement(context, progress.accuracy);
              }

              Navigator.pushNamed(context, "/reward");
            },
          ),
        ),
      );
    } else {
      // No level up, but check for accuracy achievements
      if (_checkAccuracyAchievement(oldAccuracy, progress.accuracy)) {
        _showAccuracyAchievement(context, progress.accuracy);
      }
      Navigator.pushNamed(
        context,
        "/reward",
      ); // Direct to reward if no level up
    }

    questionsAnsweredInSession = 0;
    _currentQuestionIndex = 0;
    _allQuestions = [];
    currentQuestion = null;
    notifyListeners();
  }

  bool _checkAccuracyAchievement(double oldAccuracy, double newAccuracy) {
    // Check if any accuracy threshold was crossed
    return (oldAccuracy < 90 && newAccuracy >= 90) ||
        (oldAccuracy < 75 && newAccuracy >= 75) ||
        (oldAccuracy < 50 && newAccuracy >= 50);
  }

  void _showAccuracyAchievement(BuildContext context, double accuracy) {
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

    showDialog(
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

  // Manual sync trigger
  Future<void> syncOfflineData() async {
    await _offline.syncPendingData();
  }

  // HINT SYSTEM METHODS

  Future<void> showFormulaHint(BuildContext context) async {
    if (currentQuestion == null) return;
    if (!_isHintEnabled(context, HintType.formula)) return;

    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    // Check if user can afford the hint
    if (!coinProvider.canAffordHint(HintType.formula)) {
      _showInsufficientCoinsDialog(context, HintType.formula);
      return;
    }

    _isLoadingHint = true;
    notifyListeners();

    try {
      final formula = await api.fetchFormulaHint(currentQuestion!.id);

      if (formula != null) {
        // Deduct cost
        await coinProvider.useHint(HintType.formula);
        _usedHintForCurrentQuestion = true;
        notifyListeners();

        // Show formula in bottom sheet
        if (context.mounted) {
          FormulaHintBottomSheet.show(context, formula);
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

        // Find eliminated options
        final allOptions = currentQuestion!.options
            .map((o) => o.id.toString())
            .toList();
        _eliminatedOptions = allOptions
            .where((opt) => !remainingOptions.contains(opt))
            .toList();

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
        title: const Text('Nedovoljno coina'),
        content: Text(
          'Potrebno je $cost coina za ovu pomoc. Osvoji jos coina kroz kvizove.',
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
              Navigator.pushNamed(parentContext, '/settings');
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
