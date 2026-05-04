import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Plays a one-shot chest-opening animation sequence:
/// 1. Chest drops in and bounces
/// 2. Lid pops up with a light burst
/// 3. Sparkle particles scatter outward
/// 4. Calls [onOpened] when the burst peak is reached
class ChestOpenAnimation extends StatefulWidget {
  const ChestOpenAnimation({
    super.key,
    this.size = 100,
    this.onOpened,
  });

  final double size;

  /// Called at the burst peak so the parent can reveal rewards.
  final VoidCallback? onOpened;

  @override
  State<ChestOpenAnimation> createState() => _ChestOpenAnimationState();
}

class _ChestOpenAnimationState extends State<ChestOpenAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _lidController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final AnimationController _burstController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  late final AnimationController _sparkleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final Animation<double> _lidAngle = Tween<double>(
    begin: 0,
    end: -math.pi / 2.2,
  ).animate(CurvedAnimation(parent: _lidController, curve: Curves.easeOutBack));

  late final Animation<double> _burstRadius = Tween<double>(
    begin: 0,
    end: 1,
  ).animate(
    CurvedAnimation(parent: _burstController, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _burstOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.85), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.0), weight: 70),
  ]).animate(_burstController);

  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _burstController.addListener(_checkOpened);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSequence());
  }

  void _checkOpened() {
    if (!_opened && _burstController.value >= 0.28) {
      _opened = true;
      widget.onOpened?.call();
    }
  }

  Future<void> _runSequence() async {
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await _lidController.forward();
    if (!mounted) return;
    unawaited(_burstController.forward());
    unawaited(_sparkleController.forward());
  }

  @override
  void dispose() {
    _lidController.dispose();
    _burstController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final s = widget.size;

    return SizedBox(
      width: s * 2.2,
      height: s * 2.0,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Light burst
          AnimatedBuilder(
            animation: _burstController,
            builder: (_, __) {
              return Opacity(
                opacity: _burstOpacity.value,
                child: Container(
                  width: s * 2.2 * _burstRadius.value,
                  height: s * 2.2 * _burstRadius.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.tertiary.withValues(alpha: 0.7),
                        colors.tertiary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Sparkle particles
          AnimatedBuilder(
            animation: _sparkleController,
            builder: (_, __) {
              return CustomPaint(
                size: Size(s * 2.2, s * 2.0),
                painter: _SparklePainter(
                  progress: _sparkleController.value,
                  color: colors.tertiary,
                  radius: s * 0.9,
                ),
              );
            },
          ),
          // Chest body
          _ChestBody(size: s, lidAngle: _lidAngle)
              .animate()
              .slideY(
                begin: -0.5,
                end: 0,
                duration: 340.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms),
        ],
      ),
    );
  }
}

class _ChestBody extends StatelessWidget {
  const _ChestBody({required this.size, required this.lidAngle});

  final double size;
  final Animation<double> lidAngle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Chest base
          Container(
            width: size,
            height: size * 0.66,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: colors.tertiaryContainer,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(size * 0.18),
                bottomRight: Radius.circular(size * 0.18),
              ),
              border: Border.all(color: colors.tertiary, width: 2.5),
            ),
            child: Icon(Icons.star_rounded, color: colors.tertiary, size: size * 0.32),
          ),
          // Animated lid
          Positioned(
            top: 0,
            child: AnimatedBuilder(
              animation: lidAngle,
              builder: (_, __) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(lidAngle.value),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: size,
                    height: size * 0.42,
                    decoration: BoxDecoration(
                      color: colors.tertiary,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(size * 0.18),
                        topRight: Radius.circular(size * 0.18),
                      ),
                      border: Border.all(
                        color: colors.onTertiary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.card_giftcard_rounded,
                      color: colors.onTertiary,
                      size: size * 0.36,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double progress;
  final Color color;
  final double radius;

  static const _count = 10;
  static const _seeds = [
    0.0, 0.628, 1.257, 1.885, 2.513, 3.142, 3.770, 4.398, 5.027, 5.655,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < _count; i++) {
      final angle = _seeds[i];
      final dist = radius * progress;
      final sparkleSize = (6.0 + (i % 3) * 3.0) * (1 - progress * 0.6);

      paint.color = color.withValues(alpha: opacity * (i.isEven ? 0.9 : 0.6));
      canvas.drawCircle(
        center + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
        sparkleSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}
