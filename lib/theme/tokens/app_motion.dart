import 'package:flutter/widgets.dart';

class AppMotion {
  const AppMotion._();

  // ── Duration scale ──────────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration xSlow = Duration(milliseconds: 700);

  // ── Curves ──────────────────────────────────────────────────────────────
  static const Curve standard = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  // ── Reduce-Motion helper ───────────────────────────────────────────────
  /// Returns [Duration.zero] when the platform requests reduced motion,
  /// allowing callers to skip animations transparently.
  static Duration resolve(BuildContext context, Duration desired) {
    return MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : desired;
  }

  /// Returns a no-op linear curve when reduced motion is requested.
  static Curve resolveCurve(BuildContext context, Curve desired) {
    return MediaQuery.of(context).disableAnimations
        ? Curves.linear
        : desired;
  }
}
