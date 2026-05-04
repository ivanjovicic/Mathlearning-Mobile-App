import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mathlearning/services/sound_service.dart';
import 'package:mathlearning/theme/app_scale.dart';

class DailyRunBurstOverlay extends StatefulWidget {
  const DailyRunBurstOverlay({
    super.key,
    required this.text,
    this.subtitle,
    this.icon,
    this.compact = false,
    this.showParticles = false,
    this.soundEffect,
  });

  final String text;
  final String? subtitle;
  final IconData? icon;
  final bool compact;
  final bool showParticles;
  final SoundEffect? soundEffect;

  @override
  State<DailyRunBurstOverlay> createState() => _DailyRunBurstOverlayState();
}

class _DailyRunBurstOverlayState extends State<DailyRunBurstOverlay> {
  String? _lastPlayedSignature;

  @override
  void initState() {
    super.initState();
    _playSoundIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DailyRunBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _playSoundIfNeeded();
  }

  void _playSoundIfNeeded() {
    final effect = widget.soundEffect;
    if (effect == null) {
      return;
    }

    final signature = '${widget.text}|${widget.subtitle}|${effect.name}';
    if (_lastPlayedSignature == signature) {
      return;
    }

    _lastPlayedSignature = signature;
    unawaited(SoundService.instance.play(effect));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = widget.compact ? AppScale.s(230) : AppScale.s(280);

    return IgnorePointer(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) {
            return _BurstTransition(
              animation: animation,
              showParticles: widget.showParticles,
              compact: widget.compact,
              colors: colors,
              child: child,
            );
          },
          child: Container(
            key: ValueKey<String>('${widget.text}${widget.subtitle}'),
            width: width,
            padding: EdgeInsets.all(AppScale.s(widget.compact ? 16 : 20)),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppScale.radius(22)),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.38),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: AppScale.s(24),
                  spreadRadius: AppScale.s(2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: colors.primary,
                    size: AppScale.icon(34),
                  ),
                  SizedBox(height: AppScale.s(8)),
                ],
                Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style:
                      (widget.compact
                              ? textTheme.headlineSmall
                              : textTheme.displaySmall)
                          ?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                ),
                if (widget.subtitle != null) ...[
                  SizedBox(height: AppScale.s(6)),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstTransition extends StatelessWidget {
  const _BurstTransition({
    required this.animation,
    required this.showParticles,
    required this.compact,
    required this.colors,
    required this.child,
  });

  final Animation<double> animation;
  final bool showParticles;
  final bool compact;
  final ColorScheme colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    final scale = Tween<double>(begin: compact ? 0.84 : 0.68, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, animatedChild) {
        final progress = Curves.easeOutCubic.transform(animation.value);
        final particleOpacity = 1 - Curves.easeIn.transform(animation.value);

        return Opacity(
          opacity: fade.value,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (showParticles)
                ..._buildParticles(progress, particleOpacity.clamp(0.0, 1.0)),
              Transform.scale(scale: scale.value, child: animatedChild),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles(double progress, double opacity) {
    final spread = compact ? 0.8 : 1.0;
    final particles = <({Offset offset, double size, double angle, Color color})>[
      (
        offset: const Offset(-112, -28),
        size: 12,
        angle: -0.4,
        color: colors.primary,
      ),
      (
        offset: const Offset(-88, 44),
        size: 9,
        angle: 0.2,
        color: colors.secondary,
      ),
      (
        offset: const Offset(-36, -82),
        size: 10,
        angle: -0.9,
        color: colors.tertiary,
      ),
      (
        offset: const Offset(38, -88),
        size: 8,
        angle: 0.7,
        color: colors.secondary,
      ),
      (
        offset: const Offset(96, -18),
        size: 12,
        angle: 0.35,
        color: colors.primary,
      ),
      (
        offset: const Offset(104, 42),
        size: 10,
        angle: -0.2,
        color: colors.tertiary,
      ),
      (
        offset: const Offset(12, 92),
        size: 9,
        angle: 0.95,
        color: colors.secondary,
      ),
      (
        offset: const Offset(-52, 86),
        size: 8,
        angle: -0.65,
        color: colors.primary,
      ),
    ];

    return particles.map((particle) {
      final dx = AppScale.s(particle.offset.dx * spread * progress);
      final dy = AppScale.s(particle.offset.dy * spread * progress);
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: particle.angle * (0.4 + progress),
          child: Container(
            width: AppScale.s(particle.size),
            height: AppScale.s(particle.size * 0.56),
            decoration: BoxDecoration(
              color: particle.color.withValues(alpha: opacity * 0.92),
              borderRadius: BorderRadius.circular(AppScale.radius(999)),
              boxShadow: [
                BoxShadow(
                  color: particle.color.withValues(alpha: opacity * 0.35),
                  blurRadius: AppScale.s(10),
                  spreadRadius: AppScale.s(1),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(growable: false);
  }
}
