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
  bool _didScheduleFinish = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleController.forward();
    _burstController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didScheduleFinish) return;

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _scaleController.value = 1;
      _burstController.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished();
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) widget.onFinished();
      });
    }
    _didScheduleFinish = true;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.secondary;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          painter: XpBurstPainter(progress: _burstController.value, color: accent),
          size: const Size(400, 400),
        ),
        AnimatedBuilder(
          animation: _burstController,
          builder: (context, child) {
            return Container(
              width: 160 * _burstController.value,
              height: 160 * _burstController.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(
                  alpha: 0.2 * (1 - _burstController.value),
                ),
              ),
            );
          },
        ),
        ScaleTransition(
          scale: Tween<double>(
            begin: reduceMotion ? 1.0 : 0.5,
            end: reduceMotion ? 1.0 : 1.3,
          ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_scaleController),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "NOVI NIVO!",
                style: TextStyle(
                  fontSize: 34,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: accent, blurRadius: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Nivo ${widget.level}",
                style: TextStyle(
                  fontSize: 26,
                  color: accent,
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

class XpBurstPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Random random = Random();

  XpBurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    for (var i = 0; i < 20; i++) {
      final angle = 2 * pi * (i / 20);
      final radius = progress * 140;
      final dx = center.dx + radius * cos(angle);
      final dy = center.dy + radius * sin(angle);

      final paint = Paint()
        ..color = color.withValues(alpha: 1 - progress)
        ..strokeWidth = 6;

      canvas.drawCircle(Offset(dx, dy), 6 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant XpBurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
