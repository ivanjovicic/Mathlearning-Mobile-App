import 'package:flutter/material.dart';

/// Enterprise-grade snack bar builder that uses theme tokens.
///
/// Usage:
/// ```dart
/// AstraSnackBar.show(context, message: 'Saved!');
/// AstraSnackBar.error(context, message: 'Something failed');
/// AstraSnackBar.success(context, message: 'Done!');
/// ```
class AstraSnackBar {
  const AstraSnackBar._();

  /// Show a standard informational snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    return _show(context, message: message, actionLabel: actionLabel,
        onAction: onAction, duration: duration);
  }

  /// Show a success snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    return _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF16A34A),
      textColor: Colors.white,
      duration: duration,
    );
  }

  /// Show an error snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> error(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    final cs = Theme.of(context).colorScheme;
    return _show(
      context,
      message: message,
      backgroundColor: cs.errorContainer,
      textColor: cs.onErrorContainer,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Show a warning snack bar.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> warning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    return _show(
      context,
      message: message,
      backgroundColor: const Color(0xFFFFF3CD),
      textColor: const Color(0xFF664D03),
      duration: duration,
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Color? textColor,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: textColor != null ? TextStyle(color: textColor) : null,
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: textColor,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }
}
