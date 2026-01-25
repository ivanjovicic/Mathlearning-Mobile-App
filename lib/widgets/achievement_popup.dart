import 'dart:math';
import 'package:flutter/material.dart';

class AchievementPopup extends StatefulWidget {
  final String title;
  final String subtitle;
  final String icon; // emoji npr. "🔥", "🏅"

  const AchievementPopup({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<AchievementPopup> createState() => _AchievementPopupState();
}

class _AchievementPopupState extends State<AchievementPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleController.forward();
    _fadeController.forward();

    // Auto-close after 1.6 sec
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.25),
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _scaleController,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: _fadeController,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow aura
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.yellow.withValues(alpha: 0.15),
                  ),
                ),

                // Bursting particles
                CustomPaint(
                  painter: AchievementParticles(
                    progress: _scaleController.value,
                  ),
                  size: const Size(220, 220),
                ),

                // Main pop-up card
                Container(
                  padding: const EdgeInsets.all(22),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.yellow.shade400,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.3),
                        blurRadius: 18,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.icon, style: const TextStyle(fontSize: 60)),
                      const SizedBox(height: 10),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AchievementParticles extends CustomPainter {
  final double progress;

  AchievementParticles({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random();
    final center = size.center(Offset.zero);

    for (int i = 0; i < 18; i++) {
      final angle = i * (2 * pi / 18);
      final radius = (progress * 90) + rnd.nextDouble() * 4;

      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);

      final paint = Paint()
        ..color = Colors.yellow.withValues(alpha: 1 - progress)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), 5 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant AchievementParticles oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
