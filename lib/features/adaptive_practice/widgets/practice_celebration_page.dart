import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Full-screen celebration shown after an adaptive practice session completes,
/// before the detailed [PracticeSummarySheet].
///
/// The caller is responsible for pushing/popping this page. When the user taps
/// the CTA, [onContinue] is invoked (the caller should pop and show the
/// summary).
class PracticeCelebrationPage extends StatelessWidget {
  const PracticeCelebrationPage({
    super.key,
    required this.xpEarned,
    required this.correctCount,
    required this.totalQuestions,
    required this.masteryDelta,
    required this.onContinue,
  });

  final int xpEarned;
  final int correctCount;
  final int totalQuestions;
  final double masteryDelta;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final accuracy =
        totalQuestions == 0 ? 0.0 : correctCount / totalQuestions;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final String emoji;
    final String praise;
    if (accuracy >= 0.9) {
      emoji = '🔥';
      praise = "You're on fire! 🔥";
    } else if (accuracy >= 0.7) {
      emoji = '⭐';
      praise = 'Great job! ⭐';
    } else {
      emoji = '💪';
      praise = "Keep it up — you'll nail it next time! 💪";
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primaryContainer, cs.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Text(emoji, style: const TextStyle(fontSize: 72))
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 480.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: 20),
                Text(
                  praise,
                  style: tt.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate(delay: 160.ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(
                      begin: 0.15,
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
                const SizedBox(height: 32),
                _CelebrationStat(
                  label: '+$xpEarned XP earned!',
                  color: cs.primary,
                  delay: 280.ms,
                ),
                const SizedBox(height: 12),
                _CelebrationStat(
                  label: '$correctCount/$totalQuestions nailed it ✅',
                  color: cs.secondary,
                  delay: 380.ms,
                ),
                const SizedBox(height: 12),
                _CelebrationStat(
                  label: 'Skill +${(masteryDelta * 100).round()}% stronger!',
                  color: cs.tertiary,
                  delay: 480.ms,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Keep going! →',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
                    .animate(delay: 560.ms)
                    .fadeIn(duration: 260.ms)
                    .slideY(
                      begin: 0.2,
                      duration: 260.ms,
                      curve: Curves.easeOut,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationStat extends StatelessWidget {
  const _CelebrationStat({
    required this.label,
    required this.color,
    required this.delay,
  });

  final String label;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    )
        .animate(delay: delay)
        .fadeIn(duration: 280.ms)
        .slideX(begin: -0.06, duration: 280.ms, curve: Curves.easeOut);
  }
}
