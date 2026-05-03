import 'package:flutter/material.dart';

import 'package:mathlearning/features/adaptive_practice/models/practice_complete_response.dart';

class PracticeSummarySheet extends StatelessWidget {
  const PracticeSummarySheet({
    super.key,
    required this.summary,
    required this.onBackToMap,
    required this.onPracticeNext,
  });

  final PracticeCompleteResponse summary;
  final VoidCallback onBackToMap;
  final VoidCallback? onPracticeNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  summary.accuracy >= 0.7
                      ? 'You crushed it! 🎉'
                      : 'Good fight — keep training! 💪',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'Hit rate',
              value: '${(summary.accuracy * 100).round()}%',
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'XP earned', value: '+${summary.xpEarned}'),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Skill power boost',
              value: '+${(summary.masteryDelta * 100).round()}%',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${summary.correctAnswers}/${summary.answeredQuestions} nailed it ✅',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onBackToMap,
                child: const Text('Back to my map'),
              ),
            ),
            if (onPracticeNext != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onPracticeNext,
                  child: const Text('Next Challenge'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 450),
          builder: (context, valueAnimation, _) {
            return Opacity(
              opacity: valueAnimation,
              child: Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            );
          },
        ),
      ],
    );
  }
}
