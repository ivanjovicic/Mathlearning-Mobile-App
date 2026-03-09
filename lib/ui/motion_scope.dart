import 'package:flutter/material.dart';

/// InheritedWidget that provides the effective reduce-motion flag to the
/// entire subtree below AppShell.
///
/// The flag merges two sources:
///   1. ThemeController.reduceMotion  — the in-app user toggle
///   2. MediaQuery.disableAnimations  — the OS-level accessibility setting
///
/// Widgets read it via: MotionScope.of(context).reduce
class MotionScope extends InheritedWidget {
  const MotionScope({
    super.key,
    required this.reduce,
    required super.child,
  });

  /// True when animations should be suppressed.
  final bool reduce;

  static MotionScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MotionScope>();
  }

  static MotionScope of(BuildContext context) {
    final result = maybeOf(context);
    assert(result != null, 'No MotionScope found in widget tree');
    return result!;
  }

  @override
  bool updateShouldNotify(MotionScope oldWidget) => reduce != oldWidget.reduce;
}
