import 'package:flutter/material.dart';

class StreakFreezeChip extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const StreakFreezeChip({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = onTap != null;
    final bg = count > 0
        ? colorScheme.tertiaryContainer.withValues(alpha: 0.85)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.9);
    final fg =
        count > 0 ? colorScheme.onTertiaryContainer : colorScheme.onSurface;

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: count > 0
              ? colorScheme.tertiary.withValues(alpha: 0.55)
              : colorScheme.outline.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: (count > 0 ? colorScheme.tertiary : Colors.black)
                .withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ac_unit_rounded, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            'x$count',
            style: theme.textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (enabled) ...[
            const SizedBox(width: 6),
            Icon(Icons.add_rounded, size: 16, color: fg.withValues(alpha: 0.9)),
          ],
        ],
      ),
    );

    if (!enabled) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: child,
    );
  }
}

