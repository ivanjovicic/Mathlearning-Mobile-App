import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state/streak_state_machine.dart';

class AnimatedStreakBadge extends StatefulWidget {
  final int streakDays;
  final int freezeCount;

  /// Controls the visuals: flame / at-risk pulse / protected ice overlay.
  final StreakVisualState state;

  /// Called when user taps the badge (open modal/inventory).
  final VoidCallback? onTap;

  /// Set true to autoplay "protected" effect once when state==protected.
  final bool playProtectedOnce;

  const AnimatedStreakBadge({
    super.key,
    required this.streakDays,
    required this.freezeCount,
    required this.state,
    this.onTap,
    this.playProtectedOnce = true,
  });

  @override
  State<AnimatedStreakBadge> createState() => _AnimatedStreakBadgeState();
}

class _AnimatedStreakBadgeState extends State<AnimatedStreakBadge>
    with TickerProviderStateMixin {
  late final AnimationController _flameCtrl;
  late final AnimationController _riskCtrl;
  late final AnimationController _iceCtrl;
  late final AnimationController _bounceCtrl;

  bool _protectedPlayed = false;
  bool _reduceMotion = false;
  bool _depsInitialized = false;

  @override
  void initState() {
    super.initState();

    _flameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _riskCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextReduce = MediaQuery.of(context).disableAnimations;
    if (_depsInitialized && nextReduce == _reduceMotion) return;
    _depsInitialized = true;
    _reduceMotion = nextReduce;

    if (_reduceMotion) {
      _flameCtrl.stop();
      _riskCtrl.stop();
      _iceCtrl.stop();
    } else {
      if (!_flameCtrl.isAnimating) {
        _flameCtrl.repeat(reverse: true);
      }
      _syncRiskController();
      _maybePlayProtected();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedStreakBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.state != widget.state) {
      // Little bounce whenever state changes.
      if (!_reduceMotion) {
        _bounceCtrl.forward(from: 0);
      }

      _syncRiskController();

      if (widget.state == StreakVisualState.protected) {
        _maybePlayProtected(force: true);
      }
      if (widget.state != StreakVisualState.protected) {
        // allow re-play next time it becomes protected
        _protectedPlayed = false;
      }
    }
  }

  void _syncRiskController() {
    if (_reduceMotion) return;
    final isAtRisk = widget.state == StreakVisualState.atRisk;
    if (isAtRisk) {
      if (!_riskCtrl.isAnimating) {
        _riskCtrl.repeat(reverse: true);
      }
    } else {
      if (_riskCtrl.isAnimating) {
        _riskCtrl.stop();
      }
    }
  }

  void _maybePlayProtected({bool force = false}) {
    if (_reduceMotion) return;
    if (widget.state != StreakVisualState.protected) return;
    if (!widget.playProtectedOnce) {
      _iceCtrl.forward(from: 0);
      return;
    }
    if (force || !_protectedPlayed) {
      _protectedPlayed = true;
      _iceCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flameCtrl.dispose();
    _riskCtrl.dispose();
    _iceCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = const Color(0xFF111827);
    final border = const Color(0xFF1F2937);

    final isAtRisk = widget.state == StreakVisualState.atRisk;
    final isProtected = widget.state == StreakVisualState.protected;
    final isLost = widget.state == StreakVisualState.lost;

    final merged = Listenable.merge([
      _bounceCtrl,
      _flameCtrl,
      _riskCtrl,
      _iceCtrl,
    ]);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: merged,
        builder: (context, _) {
          final bounce = _reduceMotion
              ? 0.0
              : (_easeOutBack(_bounceCtrl.value) * 0.06);
          final scale = 1.0 + bounce;

          // Flame animation
          final flamePulse = _reduceMotion
              ? 1.0
              : (1.0 + (_flameCtrl.value * 0.08));
          final flameWiggle = _reduceMotion
              ? 0.0
              : (math.sin(_flameCtrl.value * math.pi * 2) * 0.05);

          // At-risk glow pulse
          final riskGlow = isAtRisk && !_reduceMotion
              ? (0.25 + _riskCtrl.value * 0.35)
              : 0.0;

          // Ice shimmer progress (0..1)
          final iceT = _reduceMotion ? 1.0 : _iceCtrl.value;
          final iceOpacity = isProtected ? _clamp01(iceT * 1.2) : 0.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border),
                boxShadow: [
                  // subtle depth
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                  // at-risk glow
                  if (isAtRisk)
                    BoxShadow(
                      color: const Color(
                        0xFFFF4D00,
                      ).withValues(alpha: riskGlow),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  // protected glow
                  if (isProtected)
                    BoxShadow(
                      color: const Color(0xFF60A5FA).withValues(
                        alpha: 0.22 + 0.28 * (1 - (iceT - 0.2).abs()),
                      ),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  if (isLost)
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon badge: flame with optional ice overlay
                      _IconCore(
                        flamePulse: flamePulse,
                        flameWiggle: flameWiggle,
                        showIce: isProtected,
                        iceOpacity: iceOpacity,
                        shimmerT: iceT,
                        lost: isLost,
                      ),
                      const SizedBox(width: 12),

                      // Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Daily Streak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '${widget.streakDays} days',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _FreezePill(count: widget.freezeCount),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitleFor(widget.state),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Protected banner (small)
                  if (isProtected)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Opacity(
                        opacity: 0.92,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF60A5FA,
                            ).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(
                                0xFF60A5FA,
                              ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Text(
                            'Streak Saved',
                            style: TextStyle(
                              color: Color(0xFFBFDBFE),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isLost)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Opacity(
                        opacity: 0.92,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Text(
                            'Streak Lost',
                            style: TextStyle(
                              color: Color(0xFFFECACA),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _subtitleFor(StreakVisualState s) {
    switch (s) {
      case StreakVisualState.normal:
        return 'Keep it going today.';
      case StreakVisualState.atRisk:
        return 'Do 1 quiz to save your streak.';
      case StreakVisualState.protected:
        return 'Freeze protected your streak.';
      case StreakVisualState.lost:
        return 'Start a new streak today.';
    }
  }

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  static double _easeOutBack(double t) {
    // nice bounce-ish easing for state changes
    const c1 = 1.70158;
    const c3 = c1 + 1;
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2);
  }
}

class _FreezePill extends StatelessWidget {
  final int count;
  const _FreezePill({required this.count});

  @override
  Widget build(BuildContext context) {
    final has = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: has
            ? const Color(0xFF60A5FA).withValues(alpha: 0.18)
            : Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: has
              ? const Color(0xFF60A5FA).withValues(alpha: 0.35)
              : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.ac_unit_rounded,
            size: 14,
            color: has ? const Color(0xFFBFDBFE) : Colors.white60,
          ),
          const SizedBox(width: 6),
          Text(
            'x$count',
            style: TextStyle(
              color: has ? const Color(0xFFBFDBFE) : Colors.white60,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCore extends StatelessWidget {
  final double flamePulse;
  final double flameWiggle;
  final bool showIce;
  final double iceOpacity;
  final double shimmerT;
  final bool lost;

  const _IconCore({
    required this.flamePulse,
    required this.flameWiggle,
    required this.showIce,
    required this.iceOpacity,
    required this.shimmerT,
    required this.lost,
  });

  @override
  Widget build(BuildContext context) {
    final flameColor = lost ? const Color(0xFF9CA3AF) : const Color(0xFFFFB74D);
    final flameGlow = lost ? Colors.transparent : const Color(0xFFFF4D00);

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // base circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
          ),

          // flame icon
          Transform.rotate(
            angle: flameWiggle,
            child: Transform.scale(
              scale: flamePulse,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: flameGlow.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 24,
                  color: flameColor,
                ),
              ),
            ),
          ),

          // ice overlay
          if (showIce)
            Opacity(
              opacity: iceOpacity,
              child: ClipOval(
                child: CustomPaint(
                  size: const Size(44, 44),
                  painter: _IcePainter(shimmerT: shimmerT),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ice overlay with shimmer + subtle cracks.
/// Kept lightweight: no shaders, just a moving gradient band.
class _IcePainter extends CustomPainter {
  final double shimmerT;
  _IcePainter({required this.shimmerT});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Frost base
    final frost = Paint()
      ..color = const Color(0xFF60A5FA).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, frost);

    // Shimmer band
    final bandX = (-size.width) + (size.width * 3) * shimmerT;
    final rect = Rect.fromLTWH(bandX, 0, size.width, size.height);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        const Color(0xFFBFDBFE).withValues(alpha: 0.55),
        Colors.transparent,
      ],
      stops: const [0.35, 0.5, 0.65],
    ).createShader(rect);

    final shimmer = Paint()
      ..shader = shader
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, radius, shimmer);

    // Tiny "crack" lines pop a bit around mid animation.
    final crackStrength = (1 - (shimmerT - 0.55).abs() * 3).clamp(0.0, 1.0);
    final crack = Paint()
      ..color = const Color(0xFFDBEAFE).withValues(alpha: 0.55 * crackStrength)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    if (crackStrength > 0.02) {
      final p = Path()
        ..moveTo(size.width * 0.22, size.height * 0.62)
        ..lineTo(size.width * 0.45, size.height * 0.40)
        ..lineTo(size.width * 0.62, size.height * 0.50)
        ..moveTo(size.width * 0.35, size.height * 0.72)
        ..lineTo(size.width * 0.55, size.height * 0.62);
      canvas.drawPath(p, crack);
    }

    // outline
    final outline = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 0.6, outline);

    // Small snowflake icon in the center.
    final snow = Paint()
      ..color = const Color(0xFFBFDBFE).withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final r = radius * 0.35;
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * math.pi * 2;
      final dx = math.cos(a) * r;
      final dy = math.sin(a) * r;
      canvas.drawLine(center, center + Offset(dx, dy), snow);
    }
  }

  @override
  bool shouldRepaint(covariant _IcePainter oldDelegate) =>
      oldDelegate.shimmerT != shimmerT;
}
