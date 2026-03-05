import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/path_node.dart';
import 'mastery_ring_indicator.dart';
import 'adaptive_difficulty_badge.dart';
import 'review_due_pill.dart';

/// The primary tile representing a single node on the Learning Path.
///
/// Covers all five visual states:
///   • Locked   — dimmed, locked icon
///   • Available — normal, tappable
///   • InProgress — highlighted border
///   • Completed — green ring + checkmark overlay
///   • Recommended — prominent "Next" banner + elevated card
class PathNodeCard extends StatelessWidget {
  final PathNode node;
  final bool isRecommended;

  /// Called when the user taps a non-locked node.
  final VoidCallback? onTap;

  const PathNodeCard({
    super.key,
    required this.node,
    this.isRecommended = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    final locked = node.isLocked;
    final completed = node.isCompleted;
    final inProgress = node.state == PathNodeState.inProgress;

    // --- Colours --------------------------------------------------------
    final cardColor = switch (node.type) {
      PathNodeType.review => cs.tertiaryContainer.withValues(alpha: 0.35),
      PathNodeType.checkpoint => cs.secondaryContainer.withValues(alpha: 0.35),
      PathNodeType.challenge => cs.errorContainer.withValues(alpha: 0.2),
      _ => cs.surfaceContainerHigh,
    };

    final borderColor = switch (true) {
      _ when isRecommended => cs.primary,
      _ when inProgress => cs.tertiary,
      _ when node.type == PathNodeType.review => const Color(0xFF00BCD4),
      _ when locked => cs.outlineVariant,
      _ => Colors.transparent,
    };

    final borderWidth = (isRecommended || inProgress) ? 2.0 : 1.0;

    // --- Ring progress colour -------------------------------------------
    final ringColor = completed
        ? const Color(0xFF27AE60)
        : (isRecommended ? cs.primary : cs.outline);

    Widget card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: locked ? cs.surfaceContainerHighest.withValues(alpha: 0.5) : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          constraints: const BoxConstraints(minHeight: 72),
          child: Row(
            children: [
              // --- Node icon / ring ---
              _NodeIcon(
                node: node,
                ringColor: ringColor,
                locked: locked,
                completed: completed,
              ),
              const SizedBox(width: 14),

              // --- Texts ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            node.topicName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: locked
                                  ? cs.onSurface.withValues(alpha: 0.4)
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                        if (isRecommended)
                          _NextBadge(),
                      ],
                    ),
                    if (node.subtopicName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        node.subtopicName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    if (!locked)
                      Row(
                        children: [
                          AdaptiveDifficultyBadge(
                            difficulty: node.difficulty,
                            showTooltip: false,
                          ),
                          const SizedBox(width: 6),
                          if (node.type == PathNodeType.review)
                            ReviewDuePill(count: node.dueReviewCount),
                        ],
                      ),
                    if (locked)
                      Text(
                        'Complete earlier nodes to unlock',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),

              // --- State icon ---
              if (completed)
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: Color(0xFF27AE60)),
              if (locked)
                Icon(Icons.lock_outline_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );

    // Entrance animation for recommended node
    if (isRecommended && !reducedMotion) {
      card = card
          .animate()
          .fadeIn(duration: 280.ms)
          .slideY(begin: 0.04, end: 0, duration: 280.ms, curve: Curves.easeOut);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _NodeIcon extends StatelessWidget {
  final PathNode node;
  final Color ringColor;
  final bool locked;
  final bool completed;

  const _NodeIcon({
    required this.node,
    required this.ringColor,
    required this.locked,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconColor = locked
        ? cs.onSurface.withValues(alpha: 0.3)
        : (completed ? const Color(0xFF27AE60) : cs.primary);

    return MasteryRingIndicator(
      progress: node.mastery / 100,
      size: 48,
      strokeWidth: 4,
      progressColor: ringColor,
      animate: !locked,
      child: Icon(_iconFor(node.type), size: 22, color: iconColor),
    );
  }

  IconData _iconFor(PathNodeType type) => switch (type) {
        PathNodeType.review => Icons.refresh_rounded,
        PathNodeType.checkpoint => Icons.flag_rounded,
        PathNodeType.challenge => Icons.timer_rounded,
        _ => Icons.menu_book_rounded,
      };
}

class _NextBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Next',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
      ),
    );
  }
}
