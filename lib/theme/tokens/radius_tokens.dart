import 'package:flutter/material.dart';

/// Standardized border-radius scale.
/// Themes reference `AppRadius.buttonFor(profile)` instead of hardcoding values.
class AppRadius {
  const AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 999;

  // Theme shape profiles — each theme picks one profile.
  // All component builders call `forProfile(profile)` to stay consistent.
  static double forProfile(ThemeShapeProfile p) => switch (p) {
        ThemeShapeProfile.soft => xl,         // Pastel
        ThemeShapeProfile.rounded => lg,      // Fantasy, SciFi
        ThemeShapeProfile.clean => 18,        // Minimal
        ThemeShapeProfile.sharp => xs,        // Retro
        ThemeShapeProfile.neon => lg,         // AstraX
      };

  static BorderRadius all(ThemeShapeProfile p) =>
      BorderRadius.circular(forProfile(p));

  static BorderRadius verticalTop(ThemeShapeProfile p) =>
      BorderRadius.vertical(top: Radius.circular(forProfile(p)));
}

/// Shape personality for each theme.
enum ThemeShapeProfile {
  soft,     // Pastel — large, friendly radii (20)
  rounded,  // Fantasy, SciFi — medium rounded (16)
  clean,    // Minimal — slightly rounded (18)
  sharp,    // Retro — nearly square (4)
  neon,     // AstraX / MLX — medium with neon accents (16)
}
