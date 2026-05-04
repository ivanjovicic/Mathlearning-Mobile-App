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
    final start = _centerOf(sourceKey);
    final end = _centerOf(targetKey);

    if (overlay == null || start == null || end == null) {
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
                duration: duration,
                particleCount: particleCount,
                onCompleted: () => complete(true),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry!);

    return completer.future.timeout(
      duration + const Duration(milliseconds: 220),
      onTimeout: () {
        complete(false);
        return false;
      },
    );
  }

  static Offset? _centerOf(GlobalKey key) {
    final context = key.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached || !renderObject.hasSize) {
      return null;
    }
    return renderObject.localToGlobal(renderObject.size.center(Offset.zero));
  }

  @override
  State<RewardFlyToTarget> createState() => _RewardFlyToTargetState();
}

class _RewardFlyToTargetState extends State<RewardFlyToTarget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener((status) {
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
            Positioned(
              left: position.dx - 14,
              top: position.dy - 14,
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
                          color: widget.color.withValues(alpha: 0.28),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(widget.icon, color: widget.color, size: 20),
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
    for (var index = 1; index <= 3; index++) {
      final trailT = math.max(0.0, t - (index * 0.09));
      final offset = _positionAt(trailT);
      trail.add(
        Positioned(
          left: offset.dx - (7 - index),
          top: offset.dy - (7 - index),
          child: Opacity(
            opacity: (0.22 - (index * 0.05)).clamp(0.04, 0.22),
            child: Container(
              width: (10 - index).toDouble(),
              height: (10 - index).toDouble(),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }
    return trail;
  }

  List<Widget> _buildParticles(double t) {
    final count = widget.particleCount.clamp(3, 6);
    final particles = <Widget>[];
    final anchor = _positionAt(t);
    final radius = 12 + (10 * (1 - t));

    for (var index = 0; index < count; index++) {
      final angle = ((math.pi * 2) / count) * index + (t * math.pi * 1.2);
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * (radius * 0.72);
      final size = 4.0 + ((count - index) * 0.6);
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
                color: widget.color.withValues(alpha: 0.88),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    return particles;
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