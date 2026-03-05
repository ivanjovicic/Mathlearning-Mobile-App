import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Circular mastery ring drawn with a [CustomPainter].
///
/// Displays a progress arc and, optionally, an icon or percentage in the
/// centre.  Sized at [size] × [size].
class MasteryRingIndicator extends StatefulWidget {
  /// Progress from 0.0 to 1.0.
  final double progress;

  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? trackColor;
  final Widget? child;
  final bool animate;

  const MasteryRingIndicator({
    super.key,
    required this.progress,
    this.size = 56,
    this.strokeWidth = 5,
    this.progressColor,
    this.trackColor,
    this.child,
    this.animate = true,
  });

  @override
  State<MasteryRingIndicator> createState() => _MasteryRingIndicatorState();
}

class _MasteryRingIndicatorState extends State<MasteryRingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animate
          ? const Duration(milliseconds: 700)
          : Duration.zero,
    );
    _animation = Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(MasteryRingIndicator old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progressColor =
        widget.progressColor ?? cs.primary;
    final trackColor =
        widget.trackColor ?? cs.outlineVariant.withValues(alpha: 0.4);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => CustomPaint(
          painter: _RingPainter(
            progress: _animation.value,
            strokeWidth: widget.strokeWidth,
            progressColor: progressColor,
            trackColor: trackColor,
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
