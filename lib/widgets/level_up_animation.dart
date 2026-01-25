import 'dart:math';
import 'package:flutter/material.dart';

class LevelUpAnimation extends StatefulWidget {
  final int level;
  final VoidCallback onFinished;

  const LevelUpAnimation({
    super.key,
    required this.level,
    required this.onFinished,
  });

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _burstController;

  @override
  void initState() {
    super.initState();

    // Zoom-in effect for "LEVEL UP"
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // XP burst particles
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleController.forward();
    _burstController.forward();

    // Automatically close animation after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), widget.onFinished);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // XP Burst
        CustomPaint(
          painter: XpBurstPainter(progress: _burstController.value),
          size: const Size(400, 400),
        ),

        // Glowing circle
        AnimatedBuilder(
          animation: _burstController,
          builder: (context, child) {
            return Container(
              width: 160 * _burstController.value,
              height: 160 * _burstController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellow.withValues(alpha: 0.2 * (1 - _burstController.value)),
              ),
            );
          },
        ),

        // LEVEL UP text
        ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOutBack))
              .animate(_scaleController),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "LEVEL UP!",
                style: TextStyle(
                  fontSize: 34,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.yellow, blurRadius: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Level ${widget.level}",
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// XP Burst Particles
class XpBurstPainter extends CustomPainter {
  final double progress;
  final Random random = Random();

  XpBurstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    for (int i = 0; i < 20; i++) {
      final angle = 2 * pi * (i / 20);
      final radius = progress * 140;
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);

      final paint = Paint()
        ..color = Colors.yellow.shade300.withValues(alpha: 1 - progress)
        ..strokeWidth = 6;

      canvas.drawCircle(Offset(dx, dy), 6 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant XpBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}