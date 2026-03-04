import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/quiz_provider.dart';
import '../widgets/ui/answer_option_card.dart';
import '../widgets/ui/state_scaffold.dart';

class QuizScreen extends StatefulWidget {
  final int? topicId;

  const QuizScreen({super.key, this.topicId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _initialized = false;
  int _subtopicId = 1;
  String? _error;

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

      if (!quiz.consumeSkipDailyReviewOnce()) {
        final daily = await quiz.getDailySrsCount();
        if (daily > 0 && mounted) {
          context.go('/daily-review');
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

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      body: SafeArea(
        child: StateScaffold(
          isLoading: _loading,
          error: _error,
          onRetry: _retryLoad,
          isEmpty: !_loading && _error == null && quiz.currentQuestion == null,
          emptyTitle: 'Nema pitanja',
          emptySubtitle: 'Startuj novu rundu ili se vrati na pocetnu.',
          emptyIcon: Icons.quiz_outlined,
          child: _QuizScaffold(
            question: quiz.currentQuestion!,
            questionNumber: quiz.currentQuestionNumber,
            totalQuestions: quiz.totalQuestions,
            onAnswer: (id) => quiz.answer(id, context),
          ),
        ),
      ),
    );
  }
}

class _QuizScaffold extends StatelessWidget {
  final dynamic question;
  final int questionNumber;
  final int totalQuestions;
  final Function(String) onAnswer;

  const _QuizScaffold({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
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
          onSelected: onAnswer,
        ),
        const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            "$questionNumber / $totalQuestions",
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

class QuizOptions extends StatefulWidget {
  final List<dynamic> options;
  final int correctId;
  final Function(String) onSelected;

  const QuizOptions({
    super.key,
    required this.options,
    required this.correctId,
    required this.onSelected,
  });

  @override
  State<QuizOptions> createState() => _QuizOptionsState();
}

class _QuizOptionsState extends State<QuizOptions> {
  String? selectedId;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: widget.options.map((option) {
          final id = option.id.toString();
          final selected = id == selectedId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnswerOptionCard(
              text: option.text,
              selected: selected,
              enabled: !_isSubmitting,
              onTap: () {
                if (_isSubmitting) return;
                setState(() {
                  selectedId = id;
                  _isSubmitting = true;
                });
                widget.onSelected(id);
                Future.delayed(const Duration(milliseconds: 250), () {
                  if (!mounted) return;
                  setState(() => _isSubmitting = false);
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class QuizBody extends StatelessWidget {
  final dynamic question;

  const QuizBody({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final text = question?.questionText ?? question?.text ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: theme.textTheme.titleLarge),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
