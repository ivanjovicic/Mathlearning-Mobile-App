import 'dart:math';
import 'package:flutter/material.dart';

class GlassBreakTransition extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;

  const GlassBreakTransition({
    super.key,
    required this.child,
    required this.trigger,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<GlassBreakTransition> createState() => _GlassBreakTransitionState();
}

class _GlassBreakTransitionState extends State<GlassBreakTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random rand = Random();

  late List<_GlassShard> shards;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    // Generate shards
    shards = List.generate(24, (_) {
      final angle = rand.nextDouble() * pi * 2;
      return _GlassShard(
        angle: angle,
        distance: rand.nextDouble() * 0.25 + 0.1,
        opacity: rand.nextDouble() * 0.3 + 0.7,
        rotation: rand.nextDouble() * 0.4 - 0.2,
      );
    });
  }

  @override
  void didUpdateWidget(covariant GlassBreakTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.trigger && !_controller.isAnimating) {
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
    final t = Curves.easeOutCubic.transform(_controller.value);

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        widget.child, // new screen

        if (_controller.value < 1)
          IgnorePointer(
            child: CustomPaint(
              painter: _GlassBreakPainter(shards: shards, t: t),
              child: Container(),
            ),
          ),
      ],
    );
  }
}

class _GlassShard {
  final double angle;
  final double distance;
  final double opacity;
  final double rotation;

  _GlassShard({
    required this.angle,
    required this.distance,
    required this.opacity,
    required this.rotation,
  });
}

class _GlassBreakPainter extends CustomPainter {
  final List<_GlassShard> shards;
  final double t;

  _GlassBreakPainter({required this.shards, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Cracks
    final crackPaint = Paint()
      ..color = Colors.white.withAlpha(((1 - t) * 0.8 * 255).round())
      ..strokeWidth = (1 - t) * 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var s in shards) {
      final dx = cos(s.angle) * size.width * .2 * (t + 0.15);
      final dy = sin(s.angle) * size.height * .2 * (t + 0.15);
      canvas.drawLine(center, center + Offset(dx, dy), crackPaint);
    }

    // Shards (broken fragments)
    final shardPaint = Paint()
      ..color = Colors.white.withAlpha(((1 - t) * 0.5 * 255).round())
      ..style = PaintingStyle.stroke;

    for (var s in shards) {
      final dx = cos(s.angle) * size.width * s.distance * t * 1.6;
      final dy = sin(s.angle) * size.height * s.distance * t * 1.6;

      canvas.save();

      canvas.translate(center.dx + dx, center.dy + dy);
      canvas.rotate(s.rotation * t);

      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(12, -18)
        ..lineTo(6, 2)
        ..close();

      shardPaint.color = Colors.white.withAlpha(
        (s.opacity * (1 - t) * 255).round(),
      );

      canvas.drawPath(path, shardPaint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
