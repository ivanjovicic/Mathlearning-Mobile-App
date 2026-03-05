import 'package:flutter/material.dart';

import '../models/path_node.dart';

/// Small chip showing difficulty and optional confidence.
class AdaptiveDifficultyBadge extends StatelessWidget {
  final DifficultyLevel difficulty;
  final ConfidenceLevel? confidence;
  final bool showTooltip;

  const AdaptiveDifficultyBadge({
    super.key,
    required this.difficulty,
    this.confidence,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = _meta(context);

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (confidence != null) ...[
            const SizedBox(width: 6),
            Text(
              '- $_confidenceLabel',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );

    if (!showTooltip) return badge;

    return Tooltip(
      message:
          'Difficulty adapts to your recent accuracy and review schedule.',
      padding: const EdgeInsets.all(10),
      child: badge,
    );
  }

  (String, Color) _meta(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return switch (difficulty) {
      DifficultyLevel.easy => ('Easy', const Color(0xFF27AE60)),
      DifficultyLevel.medium => ('Medium', cs.tertiary),
      DifficultyLevel.hard => ('Hard', cs.error),
    };
  }

  IconData get _icon => switch (difficulty) {
        DifficultyLevel.easy => Icons.sentiment_satisfied_rounded,
        DifficultyLevel.medium => Icons.local_fire_department_rounded,
        DifficultyLevel.hard => Icons.bolt_rounded,
      };

  String get _confidenceLabel => switch (confidence!) {
        ConfidenceLevel.low => 'Low confidence',
        ConfidenceLevel.med => 'Med confidence',
        ConfidenceLevel.high => 'High confidence',
      };
}
