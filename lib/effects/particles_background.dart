import 'dart:math';
import 'package:flutter/material.dart';

class ParticlesBackground extends StatefulWidget {
  final int count;
  final Color color;

  const ParticlesBackground({super.key, this.count = 55, required this.color});

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> particles;

  @override
  void initState() {
    super.initState();
    final rand = Random();

    particles = List.generate(widget.count, (index) {
      return _Particle(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        // slightly larger sizes for better visibility on big screens
        size: rand.nextDouble() * 4 + 1.2,
        // a touch faster base speed so particles drift pleasantly
        speed: rand.nextDouble() * 0.0012 + 0.00035,
        // slightly reduced max opacity for subtlety
        opacity: rand.nextDouble() * 0.55 + 0.15,
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 45000),
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
      builder: (_, __) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: particles,
            color: widget.color,
            time: _controller.value,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double time;

  _ParticlePainter({
    required this.particles,
    required this.color,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var p in particles) {
      // update position
      p.y += p.speed * 60; // velocity scaling
      if (p.y > 1) p.y = 0;

      final dx = p.x * size.width;
      final dy = p.y * size.height;

      paint.color = color.withAlpha((p.opacity * 255).round());

      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
