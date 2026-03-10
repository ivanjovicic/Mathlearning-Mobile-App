import 'package:flutter/material.dart';

import '../../theme/tokens/app_motion.dart';

/// Motion-aware transition wrapper that respects [MediaQuery.disableAnimations].
///
/// When reduced motion is active, the child is shown immediately without
/// any transition. Otherwise a configurable transition is applied.
///
/// Built-in transitions:
///   [MotionTransition.fade]
///   [MotionTransition.fadeSlide]
///   [MotionTransition.scale]
class MotionTransition extends StatelessWidget {
  final Widget child;
  final bool visible;
  final Duration? duration;
  final Curve? curve;
  final _MotionType _type;
  final Offset? slideOffset;

  const MotionTransition.fade({
    super.key,
    required this.child,
    this.visible = true,
    this.duration,
    this.curve,
  })  : _type = _MotionType.fade,
        slideOffset = null;

  const MotionTransition.fadeSlide({
    super.key,
    required this.child,
    this.visible = true,
    this.duration,
    this.curve,
    this.slideOffset,
  }) : _type = _MotionType.fadeSlide;

  const MotionTransition.scale({
    super.key,
    required this.child,
    this.visible = true,
    this.duration,
    this.curve,
  })  : _type = _MotionType.scale,
        slideOffset = null;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return visible ? child : const SizedBox.shrink();
    }

    final effectiveDuration = duration ?? AppMotion.normal;
    final effectiveCurve = curve ?? AppMotion.standard;

    return AnimatedSwitcher(
      duration: effectiveDuration,
      switchInCurve: effectiveCurve,
      switchOutCurve: effectiveCurve,
      transitionBuilder: (child, animation) => switch (_type) {
        _MotionType.fade => FadeTransition(
            opacity: animation,
            child: child,
          ),
        _MotionType.fadeSlide => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: slideOffset ?? const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        _MotionType.scale => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          ),
      },
      child: visible
          ? KeyedSubtree(key: const ValueKey('visible'), child: child)
          : const SizedBox.shrink(key: ValueKey('hidden')),
    );
  }
}

enum _MotionType { fade, fadeSlide, scale }

/// Standard page route transitions that respect reduced motion.
class AppPageTransitions {
  const AppPageTransitions._();

  /// Fade transition for page routes.
  static Widget fadeTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return FadeTransition(opacity: animation, child: child);
  }

  /// Slide-up transition for page routes.
  static Widget slideUpTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final tween = Tween(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).chain(CurveTween(curve: AppMotion.standard));
    return SlideTransition(
      position: animation.drive(tween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  /// Shared-axis horizontal transition for page routes.
  static Widget sharedAxisTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final slideTween = Tween(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: AppMotion.standard));
    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}
