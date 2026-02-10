import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_i18n.dart';
import '../state/quiz_provider.dart';
import '../theme/astrax_theme.dart';
import '../widgets/astrax_buttons.dart';
import '../widgets/astrax_card.dart';
import 'home/gamified_quiz_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _loading = true;
  bool _hasInitialized = false;
  int _subtopicId = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasInitialized) return;

    _hasInitialized = true;
    _subtopicId = ModalRoute.of(context)?.settings.arguments as int? ?? 1;
    _startQuiz();
  }

  Future<void> _startQuiz() async {
    final quiz = Provider.of<QuizProvider>(context, listen: false);
    if (!quiz.consumeSkipDailyReviewOnce()) {
      final dailyCount = await quiz.getDailySrsCount();
      if (dailyCount > 0) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, "/daily-review");
        return;
      }
    }
    await quiz.startQuiz(_subtopicId, 10);

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
    });
    await _startQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final quiz = Provider.of<QuizProvider>(context);
    if (_loading) {
      return Scaffold(
        backgroundColor: AstraXTheme.bg,
        body: Center(
          child: const CircularProgressIndicator(color: AstraXTheme.neonBlue),
        ),
      );
    }

    final question = quiz.currentQuestion;
    if (question == null) {
      return Scaffold(
        backgroundColor: AstraXTheme.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AstraCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.noQuestions,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  AstraNeonButton(text: t.retry, onTap: _retry),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GamifiedQuizScreen(
      question: question,
      questionNumber: quiz.currentQuestionNumber,
      totalQuestions: quiz.totalQuestions,
      options: question.options
          .map(
            (option) => OptionItem(
              id: option.id.toString(),
              text: option.text,
              isCorrect: option.id == question.correctAnswerId,
            ),
          )
          .toList(),
      onSubmit: (answerId) async {
        await quiz.answer(answerId, context);
      },
    );
  }
}
