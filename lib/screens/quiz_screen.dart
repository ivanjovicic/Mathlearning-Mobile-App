import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/quiz_provider.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _initialized = false;
  int _subtopicId = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    _subtopicId =
        ModalRoute.of(context)?.settings.arguments as int? ?? 1;

    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    final quiz = context.read<QuizProvider>();

    if (!quiz.consumeSkipDailyReviewOnce()) {
      final daily = await quiz.getDailySrsCount();
      if (daily > 0 && mounted) {
        Navigator.pushReplacementNamed(context, "/daily-review");
        return;
      }
    }

    await quiz.startQuiz(_subtopicId, 10);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const _QuizLoadingSkeleton();
    }

    if (quiz.currentQuestion == null) {
      return const _QuizEmptyState();
    }

    return _QuizScaffold(
      question: quiz.currentQuestion!,
      questionNumber: quiz.currentQuestionNumber,
      totalQuestions: quiz.totalQuestions,
      onAnswer: (id) => quiz.answer(id, context),
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            QuizHeader(
              questionNumber: questionNumber,
              totalQuestions: totalQuestions,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: QuizBody(
                  key: ValueKey(question.id),
                  question: question,
                ),
              ),
            ),
            QuizOptions(
              options: question.options,
              correctId: question.correctAnswerId,
              onSelected: onAnswer,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: widget.options.map((option) {
          final id = option.id.toString();
          final selected = id == selectedId;

          return GestureDetector(
            onTap: () {
              setState(() => selectedId = id);
              widget.onSelected(id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: selected
                    ? cs.primary.withOpacity(0.15)
                    : cs.surfaceContainerHighest,
                border: Border.all(
                  color: selected ? cs.primary : cs.outline,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuizLoadingSkeleton extends StatelessWidget {
  const _QuizLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _QuizEmptyState extends StatelessWidget {
  const _QuizEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_rounded, size: 56),
              const SizedBox(height: 12),
              Text('Nema pitanja', style: t.textTheme.titleLarge),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text('Nazad'),
              ),
            ],
          ),
        ),
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
            Text(
              text,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
