import 'dart:math';
import 'package:flutter/material.dart';

class SparkBurst extends StatefulWidget {
  final Color color;
  final bool trigger;

  const SparkBurst({super.key, required this.color, required this.trigger});

  @override
  State<SparkBurst> createState() => _SparkBurstState();
}

class _SparkBurstState extends State<SparkBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void didUpdateWidget(covariant SparkBurst oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _BurstPainter(
              color: widget.color,
              t: _controller.value,
              rand: rand,
            ),
          );
        },
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  final Color color;
  final Random rand;

  _BurstPainter({required this.t, required this.color, required this.rand});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final center = Offset(size.width / 2, size.height / 2);
    final count = 32;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi;
      final dist = (t * 260) * (0.45 + rand.nextDouble() * 0.9);

      final dx = center.dx + cos(angle) * dist;
      final dy = center.dy + sin(angle) * dist;

      // make fade non-linear for a snappier burst
      final fade = pow(1 - t, 1.6).toDouble();
      paint.color = color.withAlpha((fade.clamp(0.0, 1.0) * 255).round());
      paint.strokeCap = StrokeCap.round;
      paint.strokeWidth = (1.8 - (t * 1.6)).clamp(0.6, 2.2);

      canvas.drawLine(center, Offset(dx, dy), paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
