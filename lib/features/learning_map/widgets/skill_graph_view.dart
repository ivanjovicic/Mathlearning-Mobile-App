import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/skill_node_state.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/features/learning_map/widgets/skill_node_bubble.dart';
import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';

class SkillGraphView extends StatelessWidget {
  const SkillGraphView({
    super.key,
    required this.nodes,
    required this.onNodeTap,
    this.focusedNodeId,
  });

  final List<SkillNode> nodes;
  final ValueChanged<SkillNode> onNodeTap;
  final String? focusedNodeId;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
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
      key: const Key('learning_map_graph_list'),
      padding: EdgeInsets.fromLTRB(
        context.spacing.m,
        context.spacing.s + context.spacing.xs,
        context.spacing.m,
        AppScale.s(180),
      ),
      itemCount: nodes.length * 2 - 1,
      itemBuilder: (context, index) {
        if (index.isOdd) {
          final nodeIndex = index ~/ 2;
          return _ConnectorSegment(
            fromAlignment: _alignmentForIndex(nodeIndex),
            toAlignment: _alignmentForIndex(nodeIndex + 1),
          );
        }

        final nodeIndex = index ~/ 2;
        final node = nodes[nodeIndex];
        final alignment = _alignmentForIndex(nodeIndex);
        return Align(
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
                onTap: () => onNodeTap(viewModel.node),
              );
            },
          ),
        );
      },
    );
  }

  Alignment _alignmentForIndex(int index) {
    final cycle = index % 3;
    if (cycle == 0) return Alignment.centerLeft;
    if (cycle == 1) return Alignment.center;
    return Alignment.centerRight;
  }

  String _semanticLabel(_NodeViewModel vm) {
    final stateText = switch (vm.state) {
      SkillNodeState.locked => 'locked',
      SkillNodeState.learning => 'in progress',
      SkillNodeState.mastered => 'mastered',
      SkillNodeState.recommended => 'recommended next',
    };
    final percent = (vm.progress * 100).round();
    return '${vm.node.title}, $percent% mastered, $stateText';
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
