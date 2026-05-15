import 'package:flutter/material.dart';

class WeeklyFeaturedFlairChip extends StatelessWidget {
  const WeeklyFeaturedFlairChip({
    super.key,
    required this.label,
    this.compact = false,
    this.maxWidth,
  });

  final String label;
  final bool compact;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = colors.tertiary;
    return Tooltip(
      message: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Container(
          key: const Key('weekly_featured_completion_badge'),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.48)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: compact ? 6 : 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                color: accent,
                size: compact ? 12 : 15,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 10 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
