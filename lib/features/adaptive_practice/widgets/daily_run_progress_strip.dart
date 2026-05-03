import 'package:flutter/material.dart';

class DailyRunProgressStrip extends StatelessWidget {
  const DailyRunProgressStrip({
    super.key,
    required this.stageLabel,
    required this.stageIndex,
    required this.totalStages,
    required this.progressText,
    required this.correctStreak,
    required this.comboText,
    required this.xpMultiplier,
    required this.lastXpGain,
  });

  final String stageLabel;
  final int stageIndex;
  final int totalStages;
  final String progressText;
  final int correctStreak;
  final String? comboText;
  final double xpMultiplier;
  final int? lastXpGain;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                stageLabel,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                progressText,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (lastXpGain != null)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    key: ValueKey<int>(lastXpGain!),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '+$lastXpGain XP',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(totalStages, (index) {
              final isActive = index == stageIndex;
              final isDone = index < stageIndex;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == totalStages - 1 ? 0 : 6,
                  ),
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDone
                        ? colors.primary
                        : isActive
                        ? colors.primary.withValues(alpha: 0.55)
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Streak: $correctStreak',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'XP x${xpMultiplier.toStringAsFixed(1)}',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (comboText != null)
                Text(
                  comboText!,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
