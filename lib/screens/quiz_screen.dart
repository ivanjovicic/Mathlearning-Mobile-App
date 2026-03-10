import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/navigation_extensions.dart';
import '../models/option.dart';
import '../models/question.dart';
import '../state/quiz_provider.dart';
import '../theme/app_scale.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../widgets/math/math_renderer.dart';
import '../widgets/math/math_view_mode.dart';
import '../widgets/ui/answer_option_card.dart';
import '../widgets/ui/state_scaffold.dart';

class QuizScreen extends StatefulWidget {
  final int? topicId;
  final bool skipDailyReviewRedirect;

  const QuizScreen({
    super.key,
    this.topicId,
    this.skipDailyReviewRedirect = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _initialized = false;
  int _subtopicId = 1;
  String? _error;
  String? _lastAnswerId; // tracks selected answer for feedback colors
  bool _isAnswering = false; // prevents double-tap while cooldown animation runs

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _subtopicId = widget.topicId ?? 1;

    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    try {
      final quiz = context.read<QuizProvider>();

      final shouldSkipDailyReview =
          widget.skipDailyReviewRedirect || quiz.consumeSkipDailyReviewOnce();

      if (!shouldSkipDailyReview) {
        final daily = await quiz.getDailySrsCount();
        if (daily > 0 && mounted) {
          context.goDailyReview();
          return;
        }
      }

      await quiz.startQuiz(_subtopicId, 10);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _retryLoad() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _initializeQuiz();
  }

  Future<void> _handleAnswer(String id, QuizProvider quiz) async {
    if (_isAnswering) return;
    setState(() {
      _lastAnswerId = id;
      _isAnswering = true;
    });
    await quiz.answer(id, context);
    // Show correct/wrong feedback for 1.2s before advancing
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() {
      _lastAnswerId = null;
      _isAnswering = false;
    });
    await quiz.goToNextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final currentQuestion = quiz.currentQuestion;

    return Scaffold(
      body: SafeArea(
        child: StateScaffold(
          isLoading: _loading,
          error: _error,
          onRetry: _retryLoad,
          isEmpty: !_loading && _error == null && currentQuestion == null,
          emptyTitle: 'Nema pitanja',
          emptySubtitle: 'Startuj novu rundu ili se vrati na pocetnu.',
          emptyIcon: Icons.quiz_outlined,
          child: Center(
            child: ConstrainedBox(
              constraints: AppScale.centeredContentConstraints(),
              child: currentQuestion == null
                  ? const SizedBox.shrink()
                  : _QuizScaffold(
                      question: currentQuestion,
                      questionNumber: quiz.currentQuestionNumber,
                      totalQuestions: quiz.totalQuestions,
                      lastAnswerId: _lastAnswerId,
                      isAnswering: _isAnswering,
                      onAnswer: (id) => _handleAnswer(id, quiz),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizScaffold extends StatelessWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;
  final String? lastAnswerId;
  final bool isAnswering;
  final Function(String) onAnswer;

  const _QuizScaffold({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.lastAnswerId,
    required this.isAnswering,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuizHeader(
          questionNumber: questionNumber,
          totalQuestions: totalQuestions,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: QuizBody(key: ValueKey(question.id), question: question),
          ),
        ),
        QuizOptions(
          options: question.options,
          correctId: question.correctAnswerId,
          lastAnswerId: lastAnswerId,
          isAnswering: isAnswering,
          onSelected: onAnswer,
        ),
        SizedBox(height: AppSpacing.sectionSpacing),
      ],
    );
  }
}

class QuizHeader extends StatelessWidget {
  final int questionNumber;
  final int totalQuestions;

  const QuizHeader({
    super.key,
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final progress = questionNumber / totalQuestions;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.spacingM),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: AppScale.s(8),
                borderRadius: BorderRadius.circular(AppScale.radius(20)),
              );
            },
          ),
          SizedBox(height: AppSpacing.itemSpacing),
          Text(
            '$questionNumber / $totalQuestions',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class QuizOptions extends StatelessWidget {
  final List<Option> options;
  final int correctId;
  final String? lastAnswerId;
  final bool isAnswering;
  final Function(String) onSelected;

  const QuizOptions({
    super.key,
    required this.options,
    required this.correctId,
    required this.lastAnswerId,
    required this.isAnswering,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacingM),
      child: Column(
        children: options.map((option) {
          final id = option.id.toString();
          final selected = id == lastAnswerId;
          final showFeedback = isAnswering && lastAnswerId != null;
          final isCorrectOption = option.id == correctId;
          final isWrong = showFeedback && selected && !isCorrectOption;
          final isCorrect = showFeedback && isCorrectOption;

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.itemSpacing),
            child: AnswerOptionCard(
              text: option.text,
              selected: selected,
              correct: isCorrect,
              wrong: isWrong,
              enabled: !isAnswering,
              onTap: isAnswering ? null : () => onSelected(id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class QuizBody extends StatelessWidget {
  final Question question;

  const QuizBody({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.spacingM,
        vertical: AppSpacing.base,
      ),
      child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            MathRenderer(
              value: question.text,
              mode: MathViewMode.questionStem,
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: AppScale.s(18)),
          ],
        ),
      ),
    );
  }
}
