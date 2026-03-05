import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/path_node.dart';
import '../state/learning_path_provider.dart';
import '../widgets/path_header.dart';
import '../widgets/path_node_card.dart';
import '../widgets/path_connector.dart';
import '../widgets/path_node_details_sheet.dart';

/// The Learning Path screen — primary learning surface.
///
/// Shows a vertically scrolling "path map" of [PathNode]s, each connected
/// by a [PathConnector] line.  Tapping a non-locked node opens a
/// [PathNodeDetailsSheet] with start CTA.
///
/// Data is pulled from [LearningPathProvider] which handles adaptive
/// backend + SRS/progress fallback.
class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({super.key});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    // Defer to next frame — provider may still be constructing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LearningPathProvider>().loadPath();
      context
          .read<LearningPathProvider>()
          .logEvent('path_opened');
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningPathProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            floating: false,
            toolbarHeight: 0,
            expandedHeight: 80,
            flexibleSpace: const PathHeader(),
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            shadowColor: cs.shadow.withValues(alpha: 0.1),
            elevation: 1,
          ),
        ],
        body: _buildBody(context, provider),
      ),

      // Floating "Review due" FAB
      floatingActionButton: provider.dueReviewCount > 0
          ? _ReviewFab(count: provider.dueReviewCount, nodes: provider.nodes)
          : null,
    );
  }

  Widget _buildBody(BuildContext context, LearningPathProvider provider) {
    // --- Loading skeleton ---
    if (provider.isLoading && provider.nodes.isEmpty) {
      return _SkeletonList();
    }

    // --- Error state ---
    if (provider.error != null && provider.nodes.isEmpty) {
      return _ErrorView(
        message: provider.error!,
        onRetry: () => provider.loadPath(forceRefresh: true),
      );
    }

    // --- Empty state ---
    if (provider.nodes.isEmpty) {
      return const _EmptyView();
    }

    final nodes = provider.nodes;
    final recommended = provider.recommended;

    return RefreshIndicator(
      onRefresh: () => provider.loadPath(forceRefresh: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (provider.isRetrying)
            const SliverToBoxAdapter(child: _RetryingBanner()),

          // Offline / fallback banner
          if (provider.isOfflineFallback)
            SliverToBoxAdapter(child: _OfflineBanner()),
          if (provider.isCached)
            const SliverToBoxAdapter(child: _CachedBanner()),

          // Path nodes list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // Each "item" is a node + optional connector below it.
                  // We use (nodes.length * 2 - 1) slots.
                  if (index.isOdd) {
                    // Connector between two nodes
                    final nodeIndex = index ~/ 2;
                    final nextLocked = isNextNodeLocked(nodes, nodeIndex);
                    return Center(
                      child: PathConnector(nextNodeLocked: nextLocked),
                    );
                  }

                  final nodeIndex = index ~/ 2;
                  final node = nodes[nodeIndex];
                  final isRec = node.id == recommended?.id;

                  return PathNodeCard(
                    node: node,
                    isRecommended: isRec,
                    onTap: () {
                      provider.logEvent('node_tapped', {
                        'nodeId': node.id,
                        'type': node.type.name,
                      });
                      showPathNodeDetailsSheet(context, node: node);
                    },
                  );
                },
                childCount: nodes.length * 2 - 1,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _ReviewFab extends StatelessWidget {
  final int count;
  final List<PathNode> nodes;

  const _ReviewFab({required this.count, required this.nodes});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF00BCD4);
    return FloatingActionButton.extended(
      onPressed: () {
        final reviewNode = nodes.firstWhere(
          (n) => n.type == PathNodeType.review,
          orElse: () => nodes.first,
        );
        showPathNodeDetailsSheet(context, node: reviewNode);
      },
      backgroundColor: color,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.refresh_rounded),
      label: Text('$count due'),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.tertiaryContainer.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: cs.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached path — some data may be outdated',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.tertiary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CachedBanner extends StatelessWidget {
  const _CachedBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer.withValues(alpha: 0.32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Loaded from cache while waiting for fresh data',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryingBanner extends StatelessWidget {
  const _RetryingBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.secondaryContainer.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Retrying connection to adaptive service...',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSecondaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not load learning path',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded,
              size: 56, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text('Your learning path is being built',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Complete a quiz to get personalised recommendations.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Simple skeleton placeholder list while data is loading.
class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 900.ms, color: cs.surface.withValues(alpha: 0.4)),
    );
  }
}
