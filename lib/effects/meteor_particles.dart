import 'dart:math';
import 'package:flutter/material.dart';

class MeteorParticles extends StatefulWidget {
  final int count;
  final Color color;

  const MeteorParticles({super.key, this.count = 14, required this.color});

  @override
  State<MeteorParticles> createState() => _MeteorParticlesState();
}

class _MeteorParticlesState extends State<MeteorParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random rand = Random();

  late List<_Meteor> meteors;

  @override
  void initState() {
    super.initState();

    meteors = List.generate(widget.count, (_) {
      return _Meteor(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        // longer streaks for a more dramatic look
        length: rand.nextDouble() * 90 + 60,
        // faster meteors for snappier motion
        speed: rand.nextDouble() * 0.006 + 0.0035,
        thickness: rand.nextDouble() * 2.2 + 0.8,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return CustomPaint(
          painter: _MeteorPainter(
            meteors: meteors,
            time: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _Meteor {
  double x;
  double y;
  double length;
  double speed;
  double thickness;

  _Meteor({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.thickness,
  });
}

class _MeteorPainter extends CustomPainter {
  final List<_Meteor> meteors;
  final double time;
  final Color color;

  _MeteorPainter({
    required this.meteors,
    required this.time,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      // slightly softer meteor opacity
      ..color = color.withAlpha((0.6 * 255).round());

    for (var m in meteors) {
      m.x += m.speed * 2;
      m.y += m.speed;

      if (m.y > 1 || m.x > 1) {
        m.x = Random().nextDouble();
        m.y = 0;
      }

      final start = Offset(m.x * size.width, m.y * size.height);
      final end = Offset(start.dx - m.length, start.dy - m.length * 0.5);

      paint.strokeWidth = m.thickness;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
