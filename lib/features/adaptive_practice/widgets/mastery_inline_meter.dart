import 'package:flutter/material.dart';

class MasteryInlineMeter extends StatelessWidget {
  const MasteryInlineMeter({
    super.key,
    required this.before,
    required this.after,
  });

  final double before;
  final double after;

  @override
  Widget build(BuildContext context) {
    final safeBefore = before.clamp(0.0, 1.0);
    final safeAfter = after.clamp(0.0, 1.0);
    final delta = safeAfter - safeBefore;
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Mastery',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(safeBefore * 100).round()}% -> ${(safeAfter * 100).round()}%',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: safeBefore, end: safeAfter),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
              );
            },
          ),
          if (delta > 0) ...[
            const SizedBox(height: 6),
            Text(
              '+${(delta * 100).round()}% this session',
              style: textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
