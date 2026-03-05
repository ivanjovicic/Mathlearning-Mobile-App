import 'package:flutter/material.dart';

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
    const color = Color(0xFF00BCD4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh_rounded, size: 13, color: color),
          const SizedBox(width: 4),
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
