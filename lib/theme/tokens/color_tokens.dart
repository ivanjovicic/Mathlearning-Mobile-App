import 'package:flutter/material.dart';

/// Shared semantic color tokens used across all themes.
/// Each theme supplies its own palette implementing these roles.
abstract class ColorTokens {
  // --- Brand ---
  Color get primary;
  Color get onPrimary;
  Color get primaryContainer;
  Color get onPrimaryContainer;

  Color get secondary;
  Color get onSecondary;
  Color get secondaryContainer;
  Color get onSecondaryContainer;

  Color get tertiary;
  Color get onTertiary;
  Color get tertiaryContainer;
  Color get onTertiaryContainer;

  // --- Surface ---
  Color get surface;
  Color get onSurface;
  Color get surfaceContainerHighest;
  Color get onSurfaceVariant;
  Color get surfaceContainer;
  Color get surfaceContainerHigh;
  Color get surfaceContainerLow;

  // --- Utility ---
  Color get outline;
  Color get outlineVariant;
  Color get error;
  Color get onError;
  Color get errorContainer;
  Color get onErrorContainer;

  // --- Semantic (optional — some themes shade these differently) ---
  Color get success;
  Color get warning;
  Color get info;
}

/// Convenience shared semantic constants that are theme-independent.
class SharedSemanticColors {
  const SharedSemanticColors._();

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF2196F3);
}
