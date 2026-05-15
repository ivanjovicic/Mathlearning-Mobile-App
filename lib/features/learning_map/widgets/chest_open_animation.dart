import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// One-shot chest-opening animation sequence:
///
/// 1. Chest drops in and bounces   (340 ms, starts immediately)
/// 2. Short lateral shake           (220 ms, after 160 ms mount delay)
/// 3. Lid pops up                   (420 ms)
/// 4. Bright light burst            (480 ms) — [onOpened] fires at ~28 %
/// 5. Sparkle particles scatter     (700 ms)
/// 6. Confetti rectangles scatter   (900 ms)
///
/// [accentColor] tints the burst, sparkles and confetti (defaults to
/// `Theme.colorScheme.tertiary`).
/// [isJackpot] strengthens the burst with a second outer ring and more
/// vivid particles – pass `true` for rare / epic / legendary rarity.
class ChestOpenAnimation extends StatefulWidget {
  const ChestOpenAnimation({
    super.key,
    this.size = 100,
    this.onOpened,
    this.accentColor,
    this.isJackpot = false,
  });

  final double size;

  /// Called at the burst peak so the parent can reveal rewards.
  final VoidCallback? onOpened;

  /// Override the burst / sparkle accent colour (defaults to tertiary).
  final Color? accentColor;

  /// Stronger burst + outer ring for rare / epic / legendary.
  final bool isJackpot;

  @override
  State<ChestOpenAnimation> createState() => _ChestOpenAnimationState();
}

class _ChestOpenAnimationState extends State<ChestOpenAnimation>
    with TickerProviderStateMixin {
  // ── controllers ───────────────────────────────────────────────────────────

  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

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

  late final AnimationController _confettiController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // ── derived animations ────────────────────────────────────────────────────

  late final Animation<double> _shakeX = TweenSequence<double>(
    [
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 25),
    ],
  ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

  late final Animation<double> _lidAngle = Tween<double>(
    begin: 0,
    end: -math.pi / 2.2,
  ).animate(CurvedAnimation(parent: _lidController, curve: Curves.easeOutBack));

  late final Animation<double> _burstRadius = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(parent: _burstController, curve: Curves.easeOutCubic),
      );

  late final Animation<double> _burstOpacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: widget.isJackpot ? 1.0 : 0.85),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(begin: widget.isJackpot ? 1.0 : 0.85, end: 0.0),
      weight: 70,
    ),
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
    await _shakeController.forward(); // 220 ms shake
    if (!mounted) return;
    await _lidController.forward(); // 420 ms lid pop
    if (!mounted) return;
    unawaited(_burstController.forward());
    unawaited(_sparkleController.forward());
    unawaited(_confettiController.forward());
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lidController.dispose();
    _burstController.dispose();
    _sparkleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? colors.tertiary;
    final s = widget.size;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) =>
          Transform.translate(offset: Offset(_shakeX.value, 0), child: child),
      child: SizedBox(
        width: s * 2.2,
        height: s * 2.0,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Primary light burst ─────────────────────────────────────
            AnimatedBuilder(
              animation: _burstController,
              builder: (context, child) {
                return Opacity(
                  opacity: _burstOpacity.value,
                  child: Container(
                    width: s * 2.2 * _burstRadius.value,
                    height: s * 2.2 * _burstRadius.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(
                            alpha: widget.isJackpot ? 0.9 : 0.7,
                          ),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // ── Secondary outer ring (jackpot only) ─────────────────────
            if (widget.isJackpot)
              AnimatedBuilder(
                animation: _burstController,
                builder: (context, child) {
                  return Opacity(
                    opacity: (_burstOpacity.value * 0.5).clamp(0.0, 1.0),
                    child: Container(
                      width: s * 3.2 * _burstRadius.value,
                      height: s * 3.2 * _burstRadius.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.55),
                            accent.withValues(alpha: 0.20),
                            accent.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
            // ── Sparkle particles ───────────────────────────────────────
            AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(s * 2.2, s * 2.0),
                  painter: _SparklePainter(
                    progress: _sparkleController.value,
                    accent: accent,
                    radius: s * 0.9,
                    isJackpot: widget.isJackpot,
                  ),
                );
              },
            ),
            // ── Confetti rectangles ─────────────────────────────────────
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(s * 2.2, s * 2.0),
                  painter: _ConfettiPainter(
                    progress: _confettiController.value,
                    accent: accent,
                    radius: s * 1.0,
                  ),
                );
              },
            ),
            // ── Chest body ──────────────────────────────────────────────
            _ChestBody(size: s, lidAngle: _lidAngle, accent: accent)
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
      ),
    );
  }
}

// ── Chest body ─────────────────────────────────────────────────────────────

class _ChestBody extends StatelessWidget {
  const _ChestBody({
    required this.size,
    required this.lidAngle,
    required this.accent,
  });

  final double size;
  final Animation<double> lidAngle;
  final Color accent;

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
              border: Border.all(color: accent, width: 2.5),
            ),
            child: Icon(Icons.star_rounded, color: accent, size: size * 0.32),
          ),
          // Animated lid
          Positioned(
            top: 0,
            child: AnimatedBuilder(
              animation: lidAngle,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(lidAngle.value),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: size,
                    height: size * 0.42,
                    decoration: BoxDecoration(
                      color: accent,
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

// ── Sparkle painter (20 particles, 3-colour mix) ───────────────────────────

class _SparklePainter extends CustomPainter {
  _SparklePainter({
    required this.progress,
    required this.accent,
    required this.radius,
    required this.isJackpot,
  });

  final double progress;
  final Color accent;
  final double radius;
  final bool isJackpot;

  static const _count = 20;
  static const _angles = [
    0.000,
    0.314,
    0.628,
    0.942,
    1.257,
    1.571,
    1.885,
    2.199,
    2.513,
    2.827,
    3.142,
    3.456,
    3.770,
    4.084,
    4.398,
    4.712,
    5.027,
    5.341,
    5.655,
    5.969,
  ];
  static const _rScale = [
    1.00,
    0.85,
    1.10,
    0.90,
    1.05,
    0.80,
    1.15,
    0.95,
    1.00,
    0.88,
    1.00,
    0.82,
    1.12,
    0.93,
    1.07,
    0.78,
    1.18,
    0.91,
    0.98,
    1.04,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final baseSize = isJackpot ? 8.0 : 6.0;
    const gold = Color(0xFFFFB800);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _count; i++) {
      final dist = radius * _rScale[i] * progress;
      final pSize = (baseSize + (i % 3) * 2.5) * (1.0 - progress * 0.6);
      final baseColor = (i % 3 == 0)
          ? accent
          : (i % 3 == 1)
          ? gold
          : Colors.white;
      paint.color = baseColor.withValues(
        alpha: opacity * (i.isEven ? 0.90 : 0.65),
      );
      canvas.drawCircle(
        center +
            Offset(math.cos(_angles[i]) * dist, math.sin(_angles[i]) * dist),
        pSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) =>
      old.progress != progress || old.isJackpot != isJackpot;
}

// ── Confetti painter (16 rotated rectangles) ───────────────────────────────

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.accent,
    required this.radius,
  });

  final double progress;
  final Color accent;
  final double radius;

  static const _count = 16;
  static const _angles = [
    0.196,
    0.589,
    0.982,
    1.374,
    1.767,
    2.160,
    2.553,
    2.945,
    3.338,
    3.731,
    4.123,
    4.516,
    4.909,
    5.301,
    5.694,
    6.087,
  ];
  static const _rotMul = [
    0.3,
    1.1,
    0.7,
    1.5,
    0.2,
    0.9,
    1.3,
    0.5,
    1.8,
    0.4,
    1.0,
    1.6,
    0.8,
    1.2,
    0.6,
    1.9,
  ];
  static const _rScale = [
    1.00,
    0.88,
    1.12,
    0.95,
    1.05,
    0.82,
    1.18,
    0.92,
    1.00,
    0.90,
    1.08,
    0.97,
    1.03,
    0.85,
    1.15,
    0.94,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final opacity = progress < 0.15
        ? (progress / 0.15).clamp(0.0, 1.0)
        : (1.0 - progress).clamp(0.0, 1.0);
    const gold = Color(0xFFFFB800);
    const coral = Color(0xFFFF6B6B);
    const mint = Color(0xFF00E5A0);
    final palette = [accent, gold, coral, mint];
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < _count; i++) {
      final dist = radius * _rScale[i] * progress;
      final selfRot = _rotMul[i] * math.pi * 2.0 * progress;
      final pos =
          center +
          Offset(math.cos(_angles[i]) * dist, math.sin(_angles[i]) * dist);
      paint.color = palette[i % palette.length].withValues(
        alpha: opacity * 0.85,
      );
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(selfRot);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 5.0, height: 9.0),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
