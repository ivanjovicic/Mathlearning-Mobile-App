import 'dart:math';

import 'package:flutter/material.dart';

class AchievementPopup extends StatefulWidget {
  final String title;
  final String subtitle;
  final String icon;

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
  bool _didScheduleClose = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didScheduleClose) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _scaleController.value = 1;
      _fadeController.value = 1;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
    _didScheduleClose = true;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.secondary;

    return Material(
      color: colorScheme.scrim.withValues(alpha: 0.25),
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
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.15),
                  ),
                ),
                CustomPaint(
                  painter: AchievementParticles(
                    progress: _scaleController.value,
                    color: accent,
                  ),
                  size: const Size(220, 220),
                ),
                Container(
                  padding: const EdgeInsets.all(22),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.8,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.icon, style: const TextStyle(fontSize: 60)),
                      const SizedBox(height: 10),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
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
  final Color color;

  AchievementParticles({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random();
    final center = size.center(Offset.zero);

    for (var i = 0; i < 18; i++) {
      final angle = i * (2 * pi / 18);
      final radius = (progress * 90) + rnd.nextDouble() * 4;
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);

      final paint = Paint()
        ..color = color.withValues(alpha: 1 - progress)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), 5 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant AchievementParticles oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
