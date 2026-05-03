import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/skill_node_state.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/features/learning_map/widgets/skill_node_bubble.dart';
import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';

class SkillGraphView extends StatefulWidget {
  const SkillGraphView({
    super.key,
    required this.nodes,
    required this.onNodeTap,
    this.focusedNodeId,
    this.celebrationNodeId,
    this.celebrationXp,
    this.autoScrollTargetNodeId,
  });

  final List<SkillNode> nodes;
  final ValueChanged<SkillNode> onNodeTap;
  final String? focusedNodeId;
  final String? celebrationNodeId;
  final int? celebrationXp;
  final String? autoScrollTargetNodeId;

  @override
  State<SkillGraphView> createState() => _SkillGraphViewState();
}

class _SkillGraphViewState extends State<SkillGraphView> {
  static const _graphNodeExtent = 204.0;

  final ScrollController _scrollController = ScrollController();
  String? _lastScrollSequenceKey;

  double get _nodeExtent => AppScale.s(_graphNodeExtent);
  double get _connectorExtent => AppScale.s(42);

  @override
  void initState() {
    super.initState();
    _scheduleScrollSequence();
  }

  @override
  void didUpdateWidget(covariant SkillGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedNodeId != widget.focusedNodeId ||
        oldWidget.celebrationNodeId != widget.celebrationNodeId ||
        oldWidget.autoScrollTargetNodeId != widget.autoScrollTargetNodeId ||
        oldWidget.nodes.length != widget.nodes.length) {
      _scheduleScrollSequence();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.m),
          child: Text(
            'Complete a few quizzes to generate your learning map',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      key: const Key('learning_map_graph_list'),
      padding: EdgeInsets.fromLTRB(
        context.spacing.m,
        context.spacing.s + context.spacing.xs,
        context.spacing.m,
        AppScale.s(180),
      ),
      itemCount: widget.nodes.length * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          final nodeIndex = index ~/ 2;
          return _ConnectorSegment(
            fromAlignment: _alignmentForIndex(nodeIndex),
            toAlignment: _alignmentForIndex(nodeIndex + 1),
          );
        }

        final nodeIndex = index ~/ 2;
        final node = widget.nodes[nodeIndex];
        final alignment = _alignmentForIndex(nodeIndex);
        return SizedBox(
          height: _nodeExtent,
          child: Align(
            alignment: alignment,
            child: Selector<LearningMapProvider, _NodeViewModel>(
              selector: (_, provider) {
                final latest = provider.findNodeById(node.id) ?? node;
                final state = provider.getNodeState(latest);
                final progress = provider.getNodeProgress(latest);
                final isRecommended = provider.path?.recommendedNext == latest.id;
                return _NodeViewModel(
                  node: latest,
                  state: state,
                  progress: progress,
                  isRecommended: isRecommended,
                );
              },
              builder: (context, viewModel, _) {
                return SkillNodeBubble(
                  key: ValueKey('skill_node_wrap_${viewModel.node.id}'),
                  node: viewModel.node,
                  state: viewModel.state,
                  progress: viewModel.progress,
                  semanticLabel: _semanticLabel(viewModel),
                  showNextLabel: viewModel.isRecommended,
                  showCompletionFeedback:
                      widget.celebrationNodeId == viewModel.node.id,
                  completionXp: widget.celebrationNodeId == viewModel.node.id
                      ? widget.celebrationXp
                      : null,
                  onTap: () => widget.onNodeTap(viewModel.node),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _scheduleScrollSequence() {
    final focusNodeId = widget.celebrationNodeId ?? widget.focusedNodeId;
    final targetNodeId = widget.autoScrollTargetNodeId;
    final sequenceKey =
        '$focusNodeId|$targetNodeId|${widget.celebrationXp}|${widget.nodes.length}';
    if (_lastScrollSequenceKey == sequenceKey) {
      return;
    }
    _lastScrollSequenceKey = sequenceKey;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      if (focusNodeId != null) {
        await _scrollToNode(focusNodeId);
      }

      if (!mounted ||
          widget.celebrationNodeId == null ||
          targetNodeId == null ||
          targetNodeId == focusNodeId) {
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      await _scrollToNode(
        targetNodeId,
        duration: const Duration(milliseconds: 650),
      );
    });
  }

  Future<void> _scrollToNode(
    String nodeId, {
    Duration duration = const Duration(milliseconds: 420),
  }) async {
    final nodeIndex = widget.nodes.indexWhere((node) => node.id == nodeId);
    if (nodeIndex < 0 || !_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final estimatedOffset =
        (nodeIndex * (_nodeExtent + _connectorExtent)) -
        ((position.viewportDimension - _nodeExtent) / 2);
    final targetOffset =
        estimatedOffset.clamp(0.0, position.maxScrollExtent).toDouble();

    if ((position.pixels - targetOffset).abs() < 4) {
      return;
    }

    await _scrollController.animateTo(
      targetOffset,
      duration: duration,
      curve: Curves.easeOutCubic,
    );
  }

  Alignment _alignmentForIndex(int index) {
    final cycle = index % 3;
    if (cycle == 0) return Alignment.centerLeft;
    if (cycle == 1) return Alignment.center;
    return Alignment.centerRight;
  }

  String _semanticLabel(_NodeViewModel vm) {
    final isCompleted = vm.progress >= 0.999;
    final stateText = switch (vm.state) {
      SkillNodeState.locked => 'locked',
      SkillNodeState.learning => 'ready to play',
      SkillNodeState.mastered => 'level complete',
      SkillNodeState.recommended => 'ready to play now',
    };
    final level = vm.progress >= 0.67 ? 3 : vm.progress >= 0.34 ? 2 : 1;
    if (isCompleted) {
      return '${vm.node.title}, done, $stateText';
    }
    if (vm.state == SkillNodeState.locked) {
      return '${vm.node.title}, locked';
    }
    return '${vm.node.title}, level $level, $stateText';
  }
}

class _ConnectorSegment extends StatelessWidget {
  const _ConnectorSegment({
    required this.fromAlignment,
    required this.toAlignment,
  });

  final Alignment fromAlignment;
  final Alignment toAlignment;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    final fromX = ((fromAlignment.x + 1) / 2) * 0.7 + 0.15;
    final toX = ((toAlignment.x + 1) / 2) * 0.7 + 0.15;
    final height = AppScale.s(42);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final x1 = width * fromX;
          final x2 = width * toX;
          return CustomPaint(
            painter: _ConnectorPainter(
              start: Offset(x1, 0),
              end: Offset(x2, height),
              color: color,
            ),
          );
        },
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.start,
    required this.end,
    required this.color,
  });

  final Offset start;
  final Offset end;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppScale.s(3)
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(
        (start.dx + end.dx) / 2,
        size.height / 2,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color;
  }
}

class _NodeViewModel {
  const _NodeViewModel({
    required this.node,
    required this.state,
    required this.progress,
    required this.isRecommended,
  });

  final SkillNode node;
  final SkillNodeState state;
  final double progress;
  final bool isRecommended;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _NodeViewModel &&
        other.node.id == node.id &&
        other.node.mastery == node.mastery &&
        other.node.isLocked == node.isLocked &&
        other.state == state &&
        other.progress == progress &&
        other.isRecommended == isRecommended;
  }

  @override
  int get hashCode => Object.hash(
    node.id,
    node.mastery,
    node.isLocked,
    state,
    progress,
    isRecommended,
  );
}
