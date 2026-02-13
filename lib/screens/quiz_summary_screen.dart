import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../l10n/app_i18n.dart';
import '../widgets/mastery_progress_bar.dart';

/// Summary screen shown after completing a quiz session.
///
/// Receives all data via [QuizSessionStats] argument (pushed from QuizProvider).
/// Uses the app theme — no hardcoded colours.
class QuizSummaryScreen extends StatefulWidget {
  const QuizSummaryScreen({super.key});

  @override
  State<QuizSummaryScreen> createState() => _QuizSummaryScreenState();
}

class _QuizSummaryScreenState extends State<QuizSummaryScreen> {
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(400.ms, () {
      if (!mounted) return;
      final stats =
          ModalRoute.of(context)?.settings.arguments as QuizSessionStats?;
      if (stats != null && stats.accuracyPercent >= 70) {
        setState(() => _showConfetti = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final t = context.t;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final stats =
        ModalRoute.of(context)?.settings.arguments as QuizSessionStats?;

    if (stats == null) {
      // Safety fallback — shouldn't happen
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            child: Text(t.qsBackHome),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // ── Trophy / result icon ──
                  _animWrap(
                    reduceMotion: reduceMotion,
                    delay: Duration.zero,
                    child: _ResultIcon(accuracy: stats.accuracyPercent, cs: cs),
                  ),

                  const SizedBox(height: 24),

                  // ── Title ──
                  _animWrap(
                    reduceMotion: reduceMotion,
                    delay: 120.ms,
                    child: Text(
                      t.qsTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  _animWrap(
                    reduceMotion: reduceMotion,
                    delay: 180.ms,
                    child: Text(
                      t.qsSubtitle(stats.correct, stats.total),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Stat cards row ──
                  _animWrap(
                    reduceMotion: reduceMotion,
                    delay: 260.ms,
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.auto_awesome_rounded,
                            label: 'XP',
                            value: '+${stats.xpEarned}',
                            color: cs.secondary,
                            cs: cs,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_fire_department_rounded,
                            label: t.qsStreak,
                            value: '${stats.streak}',
                            color: Colors.orange,
                            cs: cs,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.gps_fixed_rounded,
                            label: t.qsAccuracy,
                            value: '${stats.accuracyPercent}%',
                            color: stats.accuracyPercent >= 70
                                ? cs.tertiary
                                : cs.error,
                            cs: cs,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Mastery bar ──
                  _animWrap(
                    reduceMotion: reduceMotion,
                    delay: 340.ms,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t.qsMastery,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${(stats.masteryProgress * 100).round()}%',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        MasteryProgressBar(
                          progress: stats.masteryProgress,
                          animate: !reduceMotion,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Wrong questions review ──
                  if (stats.wrongQuestions.isNotEmpty)
                    _animWrap(
                      reduceMotion: reduceMotion,
                      delay: 420.ms,
                      child: _WrongQuestionsCard(
                        questions: stats.wrongQuestions,
                        cs: cs,
                        theme: theme,
                        t: t,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // ── Action buttons ──
                  _animWrap(
                    reduceMotion: reduceMotion,
                    delay: 500.ms,
                    child: Column(
                      children: [
                        // Play again
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/quiz',
                            ),
                            icon: const Icon(Icons.replay_rounded),
                            label: Text(
                              t.qsPlayAgain,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Back to home
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/home',
                            ),
                            icon: const Icon(Icons.home_rounded),
                            label: Text(
                              t.qsBackHome,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: cs.onSurface,
                              side: BorderSide(
                                color: cs.outline.withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // ── Confetti overlay ──
          if (_showConfetti) const _ConfettiOverlay(),
        ],
      ),
    );
  }

  Widget _animWrap({
    required bool reduceMotion,
    required Duration delay,
    required Widget child,
  }) {
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 400.ms, delay: delay)
        .moveY(begin: 20, end: 0, duration: 400.ms, delay: delay);
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          ...questions.take(5).map((q) => Padding(
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
              )),
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
              child: Container(
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
                    duration: Duration(milliseconds: 700 + rng.nextInt(700)),
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

  int get accuracyPercent =>
      total > 0 ? (correct / total * 100).round() : 0;
}
