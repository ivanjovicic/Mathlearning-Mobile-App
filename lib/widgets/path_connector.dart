import 'package:flutter/material.dart';
import '../models/path_node.dart';

/// Vertical connector line drawn between two adjacent path nodes.
///
/// The line is dashed when the next node is locked, solid otherwise.
class PathConnector extends StatelessWidget {
  final bool nextNodeLocked;
  final double height;

  const PathConnector({
    super.key,
    this.nextNodeLocked = false,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final color = nextNodeLocked
        ? Theme.of(context).colorScheme.outlineVariant
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.35);

    return SizedBox(
      width: 2,
      height: height,
      child: nextNodeLocked
          ? _DashedLine(color: color)
          : Container(color: color),
    );
  }
}

class _DashedLine extends StatelessWidget {
  final Color color;
  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashPainter(color: color));
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 5.0;
    const gapHeight = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + dashHeight).clamp(0, size.height)),
        paint,
      );
      startY += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Convenience helper — returns [PathConnector.nextNodeLocked] bool
/// given consecutive [PathNode]s.
bool isNextNodeLocked(List<PathNode> nodes, int currentIndex) {
  final nextIndex = currentIndex + 1;
  if (nextIndex >= nodes.length) return false;
  return nodes[nextIndex].isLocked;
}
