import 'package:flutter/widgets.dart';

/// Material 3 window-size classes adapted for MathLearning.
///
/// Usage:
/// ```dart
/// final bp = AppBreakpoints.of(context);
/// if (bp >= WindowSize.medium) { /* tablet layout */ }
/// ```
enum WindowSize implements Comparable<WindowSize> {
  compact,  // < 600  — phones
  medium,   // 600–839  — small tablets / foldables
  expanded, // 840–1199 — tablets
  large,    // ≥ 1200 — desktop / large tablet landscape
  ;

  bool operator >=(WindowSize other) => index >= other.index;
  bool operator >(WindowSize other) => index > other.index;
  bool operator <=(WindowSize other) => index <= other.index;
  bool operator <(WindowSize other) => index < other.index;

  @override
  int compareTo(WindowSize other) => index.compareTo(other.index);
}

class AppBreakpoints {
  const AppBreakpoints._();

  static const double compactMax = 599;
  static const double mediumMax = 839;
  static const double expandedMax = 1199;

  /// Returns the [WindowSize] for the current screen width.
  static WindowSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= compactMax) return WindowSize.compact;
    if (width <= mediumMax) return WindowSize.medium;
    if (width <= expandedMax) return WindowSize.expanded;
    return WindowSize.large;
  }

  /// Responsive value picker — returns the value matching the current size.
  ///
  /// Falls back to the next smaller defined value when a size-specific value
  /// is not provided.
  static T responsive<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    T? expanded,
    T? large,
  }) {
    final size = of(context);
    return switch (size) {
      WindowSize.large    => large ?? expanded ?? medium ?? compact,
      WindowSize.expanded => expanded ?? medium ?? compact,
      WindowSize.medium   => medium ?? compact,
      WindowSize.compact  => compact,
    };
  }

  /// Convenience: number of grid columns for the current window size.
  static int columns(BuildContext context) => responsive(
    context,
    compact: 4,
    medium: 8,
    expanded: 12,
    large: 12,
  );

  /// Content max-width for centered content areas.
  static double contentMaxWidth(BuildContext context) => responsive(
    context,
    compact: double.infinity,
    medium: 720.0,
    expanded: 960.0,
    large: 1200.0,
  );
}
