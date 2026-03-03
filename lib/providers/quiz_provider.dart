import 'package:flutter/material.dart';

/// Minimal shim of `QuizProvider` to satisfy legacy callers during migration.
class QuizProvider extends ChangeNotifier {
  dynamic currentQuestion;
  int currentQuestionNumber = 0;
  int totalQuestions = 0;

  /// Return whether we consumed a skip flag; default false.
  bool consumeSkipDailyReviewOnce() => false;

  Future<int> getDailySrsCount() async => 0;

  Future<void> startQuiz(int subtopicId, int questionCount) async {
    // Provide a minimal dummy question to keep UI compiling.
    currentQuestion = {
      'id': 'q1',
      'options': [
        {'id': 1, 'text': 'A'},
        {'id': 2, 'text': 'B'},
      ],
      'correctAnswerId': 1,
    };
    currentQuestionNumber = 1;
    totalQuestions = questionCount;
    notifyListeners();
  }

  void answer(String id, BuildContext context) {
    // No-op shim: advance to next question or clear currentQuestion
    if (currentQuestionNumber < totalQuestions) {
      currentQuestionNumber++;
      currentQuestion = {
        'id': 'q$currentQuestionNumber',
        'options': [
          {'id': 1, 'text': 'A'},
          {'id': 2, 'text': 'B'},
        ],
        'correctAnswerId': 1,
      };
    } else {
      currentQuestion = null;
    }
    notifyListeners();
  }

  // Stubs for methods referenced elsewhere
  Future<int> getPendingAnswersCount() async => 0;
  Future<int> getPendingSrsUpdatesCount() async => 0;
  Future<void> syncPendingData() async {}
}
