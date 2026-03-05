import 'package:flutter/material.dart';

/// Compact horizontal streak display for the Learning Path header.
///
/// Shows the flame icon and streak count. For full streak management
/// (freeze shop, at-risk state), use the existing [StreakBadgePresenter].
class StreakIndicator extends StatelessWidget {
  final int streak;
  final bool isAtRisk;
  final VoidCallback? onTap;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.isAtRisk = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isAtRisk ? Colors.orangeAccent : const Color(0xFFFF6B35);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAtRisk ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
