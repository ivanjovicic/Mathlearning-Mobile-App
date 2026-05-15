import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class RewardFlyToTarget extends StatefulWidget {
  const RewardFlyToTarget({
    super.key,
    required this.start,
    required this.end,
    required this.color,
    required this.icon,
    required this.debugLabel,
    this.duration = const Duration(milliseconds: 620),
    this.particleCount = 4,
    this.onCompleted,
  });

  final Offset start;
  final Offset end;
  final Color color;
  final IconData icon;
  final String debugLabel;
  final Duration duration;
  final int particleCount;
  final VoidCallback? onCompleted;

  static Future<bool> play(
    BuildContext context, {
    required GlobalKey sourceKey,
    required GlobalKey targetKey,
    required Color color,
    required IconData icon,
    required String debugLabel,
    Duration duration = const Duration(milliseconds: 620),
    int particleCount = 4,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final effectiveDuration = reduceMotion
        ? const Duration(milliseconds: 120)
        : duration;
    final start = _centerOf(sourceKey);
    final end = _centerOf(targetKey);

    if (start == null || end == null) {
      return false;
    }

    final completer = Completer<bool>();
    OverlayEntry? entry;

    void complete(bool value) {
      if (entry != null) {
        entry!.remove();
        entry = null;
      }
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    entry = OverlayEntry(
      builder: (_) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Material(
              type: MaterialType.transparency,
              child: RewardFlyToTarget(
                key: Key('reward_fly_$debugLabel'),
                start: start,
                end: end,
                color: color,
                icon: icon,
                debugLabel: debugLabel,
                duration: effectiveDuration,
                particleCount: reduceMotion ? 3 : particleCount,
                onCompleted: () => complete(true),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry!);

    return completer.future.timeout(
      effectiveDuration + const Duration(milliseconds: 220),
      onTimeout: () {
        complete(false);
        return false;
      },
    );
  }

  static Offset? _centerOf(GlobalKey key) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
  }

  @override
  State<RewardFlyToTarget> createState() => _RewardFlyToTargetState();
}

class _RewardFlyToTargetState extends State<RewardFlyToTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            widget.onCompleted?.call();
          }
        });

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        final position = _positionAt(t);
        final opacity = 1 - (t * 0.9);
        final scale = _scaleAt(t);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            ..._buildTrail(t),
            ..._buildParticles(t),
            if (t > 0.72) _buildTargetImpact(t),
            Positioned(
              left: position.dx - 18,
              top: position.dy - 18,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.44),
                          blurRadius: 22,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(widget.icon, color: widget.color, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildTrail(double t) {
    final trail = <Widget>[];
    for (var index = 1; index <= 5; index++) {
      final trailT = math.max(0.0, t - (index * 0.065));
      final offset = _positionAt(trailT);
      trail.add(
        Positioned(
          left: offset.dx - (10 - index),
          top: offset.dy - (10 - index),
          child: Opacity(
            opacity: (0.34 - (index * 0.045)).clamp(0.06, 0.34),
            child: Container(
              width: (16 - index * 1.6).toDouble(),
              height: (16 - index * 1.6).toDouble(),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.82),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.28),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return trail;
  }

  List<Widget> _buildParticles(double t) {
    final count = widget.particleCount.clamp(3, 10);
    final particles = <Widget>[];
    final anchor = _positionAt(t);
    final radius = 16 + (16 * (1 - t));

    for (var index = 0; index < count; index++) {
      final angle = ((math.pi * 2) / count) * index + (t * math.pi * 1.2);
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * (radius * 0.72);
      final size = 5.0 + ((count - index) * 0.7);
      particles.add(
        Positioned(
          left: anchor.dx + dx - (size / 2),
          top: anchor.dy + dy - (size / 2),
          child: Opacity(
            opacity: (0.7 - (t * 0.55)).clamp(0.0, 0.7),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: (index.isEven ? Colors.white : widget.color).withValues(
                  alpha: 0.92,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }

  Widget _buildTargetImpact(double t) {
    final impactT = ((t - 0.72) / 0.28).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(impactT);
    final opacity = (1 - impactT).clamp(0.0, 1.0);
    final size = 30 + eased * 54;
    return Positioned(
      key: const Key('reward_target_impact_pulse'),
      left: widget.end.dx - size / 2,
      top: widget.end.dy - size / 2,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: 0.78),
              width: 3.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45),
                blurRadius: 26,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Offset _positionAt(double t) {
    final curvedT = Curves.easeOutCubic.transform(t);
    final base = Offset.lerp(widget.start, widget.end, curvedT)!;
    final arc = math.sin(curvedT * math.pi) * 26;
    return Offset(base.dx, base.dy - arc);
  }

  double _scaleAt(double t) {
    if (t < 0.3) {
      return 0.84 + (t / 0.3) * 0.32;
    }
    return 1.16 - ((t - 0.3) / 0.7) * 0.42;
  }
}
