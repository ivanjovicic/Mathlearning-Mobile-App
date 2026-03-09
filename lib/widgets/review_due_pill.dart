import 'package:flutter/material.dart';

import '../theme/app_scale.dart';
import '../theme/theme_extensions/theme_context.dart';

/// Small badge indicating how many SRS review items are due.
///
/// Shows a cyan/teal accent to distinguish from regular lesson nodes.
class ReviewDuePill extends StatelessWidget {
  final int count;

  const ReviewDuePill({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = context.learningTheme.reviewAccent;
    final spacing = context.spacing;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.s + spacing.xs / 2,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(context.radius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh_rounded,
            size: AppScale.icon(13, min: 12, max: 16),
            color: color,
          ),
          SizedBox(width: spacing.xs),
          Text(
            '$count due',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
