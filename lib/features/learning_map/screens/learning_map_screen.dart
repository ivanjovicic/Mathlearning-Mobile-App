import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/learning_map/models/skill_node_state.dart';
import 'package:mathlearning/navigation/navigation_extensions.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_missions_carousel.dart';
import 'package:mathlearning/features/learning_map/widgets/learning_map_skeleton.dart';
import 'package:mathlearning/features/learning_map/widgets/quest_progress_list.dart';
import 'package:mathlearning/features/learning_map/widgets/skill_graph_view.dart';
import 'package:mathlearning/services/connectivity_service.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';

class LearningMapScreen extends StatefulWidget {
  const LearningMapScreen({super.key, required this.userId, this.focusNodeId});

  final String userId;
  final String? focusNodeId;

  @override
  State<LearningMapScreen> createState() => _LearningMapScreenState();
}

class _LearningMapScreenState extends State<LearningMapScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LearningMapProvider>().loadAll(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningMapProvider>();
    final path = provider.path;
    final recommendedNode = provider.recommendedNode;
    final auth = context.watch<AuthProvider>();
    final progress = context.watch<ProgressProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isOnline = ConnectivityService.instance.isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          auth.username?.isNotEmpty == true
              ? '${auth.username} - Learning Map'
              : 'Learning Map',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CompactStatsChip(
              level: progress.level,
              xp: progress.xp,
              streak: progress.streak,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refresh(widget.userId),
        child: Builder(
          builder: (context) {
            if (provider.loading && path == null) {
              return const LearningMapSkeleton();
            }

            if (provider.error != null && path == null) {
              return _ErrorState(
                message: provider.error!,
                onRetry: () => provider.refresh(widget.userId),
              );
            }

            if (path == null || path.nodes.isEmpty) {
              return _EmptyState(
                onRetry: () => provider.refresh(widget.userId),
              );
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (provider.isOfflineFallback)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 16,
                            color: colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Offline mode: showing cached learning path.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DailyMissionsCarousel(
                      missions: provider.dailyMissions,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Quests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: QuestProgressList(quests: provider.quests),
                  ),
                ),
                if (provider.recommendations.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                      child: _RecommendationSection(
                        onPracticeTap: (topicId) {
                          final nodes = path.nodes;
                          for (final node in nodes) {
                            if (node.topicId == topicId) {
                              _openPracticeForNode(node.id);
                              return;
                            }
                          }
                          if (recommendedNode != null) {
                            _openPracticeForNode(recommendedNode.id);
                          }
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                    child: Text(
                      'Skill Graph',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: SkillGraphView(
                    nodes: path.nodes,
                    focusedNodeId: widget.focusNodeId,
                    onNodeTap: (node) => _onNodeTap(context, node.id),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: recommendedNode == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: FilledButton.icon(
                key: const Key('practice_next_button'),
                onPressed: isOnline
                    ? () => _openPracticeForNode(recommendedNode.id)
                    : null,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Practice Next: ${recommendedNode.title}'),
              ),
            ),
    );
  }

  void _onNodeTap(BuildContext context, String nodeId) {
    final provider = context.read<LearningMapProvider>();
    final node = provider.findNodeById(nodeId);
    if (node == null) {
      return;
    }

    final state = provider.getNodeState(node);
    if (state == SkillNodeState.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete previous skill first')),
      );
      return;
    }

    if (!ConnectivityService.instance.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Practice needs internet connection.')),
      );
      return;
    }

    _openPracticeForNode(node.id);
  }

  void _openPracticeForNode(String nodeId) {
    if (!ConnectivityService.instance.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Practice needs internet connection.')),
      );
      return;
    }
    final provider = context.read<LearningMapProvider>();
    final node = provider.findNodeById(nodeId);
    if (node == null) {
      return;
    }
    final plan = provider.buildLaunchPlanForNode(node);
    context.startAdaptivePractice(plan);
  }
}

class _CompactStatsChip extends StatelessWidget {
  const _CompactStatsChip({
    required this.level,
    required this.xp,
    required this.streak,
  });

  final int level;
  final int xp;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Lv $level'),
          const SizedBox(width: 8),
          Text('$xp XP'),
          const SizedBox(width: 8),
          Text('Streak $streak'),
        ],
      ),
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({required this.onPracticeTap});

  final ValueChanged<int> onPracticeTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningMapProvider>();
    final items = provider.recommendations.take(3).toList(growable: false);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Practice',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.topicName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.reason,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: () => onPracticeTap(item.topicId),
                  child: const Text('Practice'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 42,
        ),
        const SizedBox(height: 14),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.route_rounded, size: 48),
        const SizedBox(height: 12),
        const Center(
          child: Text('Complete a few quizzes to generate your learning map'),
        ),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              onRetry();
            },
            child: const Text('Refresh'),
          ),
        ),
      ],
    );
  }
}
