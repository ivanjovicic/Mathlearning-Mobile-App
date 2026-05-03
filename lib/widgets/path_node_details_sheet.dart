import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/navigation_extensions.dart';
import '../models/path_node.dart';
import '../state/learning_path_provider.dart';
import 'adaptive_difficulty_badge.dart';
import 'mastery_ring_indicator.dart';
import 'node_reward_row.dart';
import 'review_due_pill.dart';

/// Modal bottom sheet shown when the user taps a [PathNodeCard].
///
/// Shows full context for the node: topic, difficulty, reasoning, rewards,
/// and the primary Start button.  Uses [showModalBottomSheet] from the caller.
///
/// Usage:
/// ```dart
/// showPathNodeDetailsSheet(context, node: node);
/// ```
class PathNodeDetailsSheet extends StatelessWidget {
  final PathNode node;

  const PathNodeDetailsSheet({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Handle ---
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Header ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MasteryRingIndicator(
                    progress: node.mastery / 100,
                    size: 56,
                    strokeWidth: 5,
                    child: Icon(
                      _iconFor(node.type),
                      size: 26,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.topicName,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (node.subtopicName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            node.subtopicName!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- Badges ---
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdaptiveDifficultyBadge(
                    difficulty: node.difficulty,
                    confidence: node.confidence,
                  ),
                  if (node.type == PathNodeType.review)
                    ReviewDuePill(count: node.dueReviewCount),
                  _TypeBadge(type: node.type),
                ],
              ),
              const SizedBox(height: 16),

              // --- Reasoning ---
              if (node.recommendationReason != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          node.recommendationReason!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // --- Rewards ---
              NodeRewardRow(
                xpReward: node.xpReward,
                estimatedMinutes: node.estimatedMinutes,
              ),
              const SizedBox(height: 20),

              // --- Mastery ---
              Row(
                children: [
                  Text('Mastery', style: theme.textTheme.labelMedium),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: node.mastery / 100,
                        minHeight: 7,
                        backgroundColor:
                            cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${node.mastery.round()}%',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.primary),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- CTA ---
              if (node.isLocked)
                _LockedCTA(node: node)
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => _startSession(context),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      node.type == PathNodeType.review
                          ? 'Review it! →'
                          : 'Let\'s go! →',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _startSession(BuildContext context) {
    // Mark node as in-progress optimistically
    context.read<LearningPathProvider>()
      ..markNodeStarted(node.id)
      ..logEvent('node_started', {'nodeId': node.id, 'type': node.type.name});

    Navigator.of(context).pop(); // close sheet
    context.openQuiz(topicId: node.topicId);
  }

  IconData _iconFor(PathNodeType type) => switch (type) {
        PathNodeType.review => Icons.refresh_rounded,
        PathNodeType.checkpoint => Icons.flag_rounded,
        PathNodeType.challenge => Icons.timer_rounded,
        _ => Icons.menu_book_rounded,
      };
}

class _TypeBadge extends StatelessWidget {
  final PathNodeType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (type) {
      PathNodeType.review => ('Review', const Color(0xFF00BCD4)),
      PathNodeType.checkpoint => ('Checkpoint', cs.secondary),
      PathNodeType.challenge => ('Challenge', cs.error),
      _ => ('Lesson', cs.primary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _LockedCTA extends StatelessWidget {
  final PathNode node;
  const _LockedCTA({required this.node});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 18,
              color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'Complete earlier nodes to unlock',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Helper function — show the sheet from anywhere.
void showPathNodeDetailsSheet(BuildContext context, {required PathNode node}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PathNodeDetailsSheet(node: node),
  );
}
