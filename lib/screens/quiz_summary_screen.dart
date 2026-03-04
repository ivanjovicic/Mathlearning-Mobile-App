import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_i18n.dart';
import '../widgets/mastery_progress_bar.dart';

class QuizSummaryScreen extends StatefulWidget {
  const QuizSummaryScreen({super.key});

  factory QuizSummaryScreen.withStats(QuizSessionStats stats) {
    return _QuizSummaryWithStats(stats: stats);
  }

  @override
  State<QuizSummaryScreen> createState() => _QuizSummaryScreenState();
}

class _QuizSummaryWithStats extends QuizSummaryScreen {
  final QuizSessionStats stats;
  const _QuizSummaryWithStats({required this.stats});
}

class _QuizSummaryScreenState extends State<QuizSummaryScreen> {
  QuizSessionStats? _stats;
  bool _showConfetti = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_stats != null) return;

    if (widget is _QuizSummaryWithStats) {
      _stats = (widget as _QuizSummaryWithStats).stats;
    } else {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is QuizSessionStats) {
        _stats = args;
      }
    }

    if (_stats != null && _stats!.accuracyPercent >= 70) {
      Future.delayed(350.ms, () {
        if (!mounted) return;
        setState(() => _showConfetti = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final stats = _stats;

    if (stats == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_rounded, size: 40),
              const SizedBox(height: 12),
              Text('No stats available', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: Text(t.qsBackHome),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          _SummaryHeader(
                            stats: stats,
                            reduceMotion: reduceMotion,
                          ),
                          const SizedBox(height: 28),
                          _SummaryStatRow(
                            stats: stats,
                            reduceMotion: reduceMotion,
                          ),
                          const SizedBox(height: 24),
                          _SummaryMasterySection(
                            stats: stats,
                            reduceMotion: reduceMotion,
                          ),
                          const SizedBox(height: 24),
                          if (stats.wrongQuestions.isNotEmpty)
                            _SummaryWrongQuestionsSection(
                              stats: stats,
                              reduceMotion: reduceMotion,
                            ),
                          const SizedBox(height: 32),
                          SummaryActions(
                            stats: stats,
                            reduceMotion: reduceMotion,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );

                return content;
              },
            ),
          ),
          if (_showConfetti)
            const _ConfettiOverlay().animate().fadeIn(duration: 250.ms),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final QuizSessionStats stats;
  final bool reduceMotion;

  const _SummaryHeader({required this.stats, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = context.t;

    final heroChild = _ResultIcon(accuracy: stats.accuracyPercent, cs: cs);

    Widget icon = Hero(tag: 'quiz-summary-result-icon', child: heroChild);

    if (!reduceMotion) {
      icon = icon
          .animate()
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 450.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(duration: 350.ms);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        icon,
        const SizedBox(height: 20),
        Text(
          t.qsTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.qsSubtitle(stats.correct, stats.total),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : 320.ms,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            '${stats.accuracyPercent}%',
            key: ValueKey(stats.accuracyPercent),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
              color: stats.accuracyPercent >= 70 ? cs.primary : cs.error,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Result icon — emoji/icon based on accuracy
// ═══════════════════════════════════════════════════════════════════════
class _ResultIcon extends StatelessWidget {
  final int accuracy;
  final ColorScheme cs;

  const _ResultIcon({required this.accuracy, required this.cs});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;

    if (accuracy >= 90) {
      icon = Icons.emoji_events_rounded;
      color = Colors.amber;
    } else if (accuracy >= 70) {
      icon = Icons.star_rounded;
      color = cs.tertiary;
    } else if (accuracy >= 50) {
      icon = Icons.thumb_up_rounded;
      color = cs.secondary;
    } else {
      icon = Icons.fitness_center_rounded;
      color = cs.error;
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Icon(icon, size: 56, color: color),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Stat card
// ═══════════════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Wrong questions review card
// ═══════════════════════════════════════════════════════════════════════
class _WrongQuestionsCard extends StatelessWidget {
  final List<WrongQuestion> questions;
  final ColorScheme cs;
  final ThemeData theme;
  final AppI18n t;

  const _WrongQuestionsCard({
    required this.questions,
    required this.cs,
    required this.theme,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review_rounded, color: cs.error, size: 22),
              const SizedBox(width: 8),
              Text(
                t.qsReviewTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${questions.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...questions
              .take(5)
              .map(
                (q) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: cs.error.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Math.tex(
                          q.questionText,
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.85),
                            height: 1.3,
                          ),
                          onErrorFallback: (_) => Text(
                            q.questionText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.85),
                              height: 1.3,
                            ),
                            softWrap: true,
                            textWidthBasis: TextWidthBasis.longestLine,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (questions.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${questions.length - 5} ${t.qsMore}',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Confetti overlay (flutter_animate, no extra dependency)
// ═══════════════════════════════════════════════════════════════════════
class _ConfettiOverlay extends StatelessWidget {
  const _ConfettiOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rng = Random(77);

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(45, (i) {
            final startX = rng.nextDouble() * size.width;
            final endY = size.height * (0.3 + rng.nextDouble() * 0.7);
            final color = [
              Colors.amber,
              Colors.redAccent,
              Colors.greenAccent,
              Colors.blueAccent,
              Colors.purpleAccent,
              Colors.orangeAccent,
              Colors.tealAccent,
            ][i % 7];

            return Positioned(
              left: startX,
              top: -20,
              child:
                  Container(
                        width: 7 + rng.nextDouble() * 7,
                        height: 7 + rng.nextDouble() * 7,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )
                      .animate()
                      .moveY(
                        begin: 0,
                        end: endY,
                        duration: Duration(
                          milliseconds: 700 + rng.nextInt(700),
                        ),
                        curve: Curves.easeIn,
                      )
                      .fadeIn(duration: 80.ms)
                      .rotate(
                        begin: 0,
                        end: rng.nextDouble() * 2.5,
                        duration: 1300.ms,
                      )
                      .fadeOut(delay: 700.ms, duration: 500.ms),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Data models for quiz session stats
// ═══════════════════════════════════════════════════════════════════════

/// A single wrong question for review display.
class WrongQuestion {
  final int questionId;
  final String questionText;
  final String userAnswer;
  final String correctAnswer;

  const WrongQuestion({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
  });
}

/// Complete stats for a finished quiz session.
class QuizSessionStats {
  final int correct;
  final int total;
  final int xpEarned;
  final int streak;
  final double masteryProgress;
  final List<WrongQuestion> wrongQuestions;

  const QuizSessionStats({
    required this.correct,
    required this.total,
    required this.xpEarned,
    required this.streak,
    required this.masteryProgress,
    required this.wrongQuestions,
  });

  int get accuracyPercent => total > 0 ? (correct / total * 100).round() : 0;
}

// ═══════════════════════════════════════════════════════════════════════
// Small private helpers referenced from the summary layout
// ═══════════════════════════════════════════════════════════════════════

class _SummaryStatRow extends StatelessWidget {
  final QuizSessionStats stats;
  final bool reduceMotion;

  const _SummaryStatRow({required this.stats, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            label: 'Correct',
            value: '${stats.correct}',
            color: cs.primary,
            cs: cs,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.timer,
            label: 'Total',
            value: '${stats.total}',
            color: cs.secondary,
            cs: cs,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star_rounded,
            label: 'XP',
            value: '${stats.xpEarned}',
            color: Colors.amber,
            cs: cs,
          ),
        ),
      ],
    );
  }
}

class _SummaryMasterySection extends StatelessWidget {
  final QuizSessionStats stats;
  final bool reduceMotion;

  const _SummaryMasterySection({
    required this.stats,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.qsMastery,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        MasteryProgressBar(progress: stats.masteryProgress),
      ],
    );
  }
}

class _SummaryWrongQuestionsSection extends StatelessWidget {
  final QuizSessionStats stats;
  final bool reduceMotion;

  const _SummaryWrongQuestionsSection({
    required this.stats,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (stats.wrongQuestions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.qsReviewTitle, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        _WrongQuestionsCard(
          questions: stats.wrongQuestions,
          cs: Theme.of(context).colorScheme,
          theme: Theme.of(context),
          t: t,
        ),
      ],
    );
  }
}

class SummaryActions extends StatelessWidget {
  final QuizSessionStats stats;
  final bool reduceMotion;

  const SummaryActions({required this.stats, required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => context.go('/quiz'),
            child: const Text('Retry'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.go('/home'),
            child: Text(t.qsBackHome),
          ),
        ),
      ],
    );
  }
}
