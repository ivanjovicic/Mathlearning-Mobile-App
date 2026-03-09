import 'package:flutter/animation.dart';

class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve emphasized = Curves.easeOutBack;
}
