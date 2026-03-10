import 'package:flutter/material.dart';

/// Semantic wrappers for enterprise-grade accessibility.
///
/// Usage:
/// ```dart
/// AppSemantics.button(
///   label: 'Start quiz',
///   child: AstraButton(onPressed: _start, child: Text('Start')),
/// )
/// ```

class AppSemantics {
  const AppSemantics._();

  /// Wraps an interactive widget with a semantic button label.
  static Widget button({
    required String label,
    required Widget child,
    String? hint,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Wraps a section with a semantic heading.
  static Widget heading({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }

  /// Wraps a status indicator (XP bar, streak) with a live-region label.
  static Widget liveRegion({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Wraps an image/icon with a descriptive label.
  static Widget image({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Marks a widget as a navigation landmark.
  static Widget navigation({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      namesRoute: true,
      label: label,
      child: child,
    );
  }

  /// Marks a value indicator (progress bar, score).
  static Widget value({
    required String label,
    required String currentValue,
    required Widget child,
    double? progressValue,
  }) {
    return Semantics(
      label: label,
      value: currentValue,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Hides decorative content from the accessibility tree.
  static Widget decorative({required Widget child}) {
    return ExcludeSemantics(child: child);
  }
}
