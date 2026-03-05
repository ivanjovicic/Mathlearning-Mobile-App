import 'dart:ui';

import 'package:flutter/material.dart';

import '../effects/meteor_particles.dart';
import '../effects/particles_background.dart';
import '../effects/spark_burst.dart';

class GameThemeTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const GameThemeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  GameThemeTransitionState createState() => GameThemeTransitionState();
}

class GameThemeTransitionState extends State<GameThemeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _blur;

  late Color oldPrimary;
  late Color newPrimary;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(
      begin: 1,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _blur = Tween<double>(
      begin: 0,
      end: 12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final primary = Theme.of(context).colorScheme.primary;
    oldPrimary = primary;
    newPrimary = primary;
  }

  void play(Color oldColor, Color newColor) {
    setState(() {
      oldPrimary = oldColor;
      newPrimary = newColor;
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAnimating = _controller.isAnimating;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              ParticlesBackground(
                count: 55,
                color:
                    Color.lerp(oldPrimary, newPrimary, _controller.value) ??
                    newPrimary,
              ),
              widget.child,
              if (isAnimating) ...[
                MeteorParticles(
                  count: 12,
                  color:
                      Color.lerp(
                        oldPrimary,
                        newPrimary,
                        _controller.value,
                      )?.withAlpha((0.6 * 255).round()) ??
                      newPrimary.withAlpha((0.6 * 255).round()),
                ),
                SparkBurst(
                  color: newPrimary,
                  trigger: _controller.status == AnimationStatus.forward,
                ),
                if (_blur.value > 0)
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blur.value,
                      sigmaY: _blur.value,
                    ),
                    child: Container(
                      color: colorScheme.scrim.withAlpha((0.10 * 255).round()),
                    ),
                  ),
                IgnorePointer(
                  child: Container(
                    color: Color.lerp(
                      oldPrimary,
                      newPrimary,
                      _controller.value,
                    )?.withAlpha((0.25 * 255).round()),
                  ),
                ),
                Opacity(
                  opacity: _fade.value,
                  child: Container(
                    color: colorScheme.scrim.withAlpha((0.6 * 255).round()),
                  ),
                ),
                Transform.scale(scale: _scale.value, child: Container()),
              ],
            ],
          ),
        );
      },
    );
  }
}
