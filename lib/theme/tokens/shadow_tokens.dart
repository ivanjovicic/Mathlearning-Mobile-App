import 'package:flutter/material.dart';

/// Reusable elevation shadow definitions.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> low = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> high = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  /// Neon glow — used by SciFi and AstraX themes.
  static List<BoxShadow> glowNeon(Color color, {double spread = 0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 12,
          spreadRadius: spread,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 24,
          spreadRadius: spread + 2,
        ),
      ];

  /// Soft glow — used by Pastel theme.
  static List<BoxShadow> glowSoft(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];
}
