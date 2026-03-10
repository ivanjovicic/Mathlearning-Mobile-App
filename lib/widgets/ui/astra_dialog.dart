import 'package:flutter/material.dart';

/// Enterprise-grade dialog that inherits theme tokens.
///
/// Usage:
/// ```dart
/// AstraDialog.show(
///   context: context,
///   title: 'Confirm',
///   content: Text('Are you sure?'),
///   confirmLabel: 'Da',
///   onConfirm: () => Navigator.pop(context, true),
/// );
/// ```
class AstraDialog extends StatelessWidget {
  final String title;
  final Widget? content;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? icon;
  final bool destructive;

  const AstraDialog({
    super.key,
    required this.title,
    this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.destructive = false,
  });

  /// Show the dialog with standard Material 3 transition.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    Widget? content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Widget? icon,
    bool destructive = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AstraDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        icon: icon,
        destructive: destructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: icon,
      title: Semantics(
        header: true,
        child: Text(title),
      ),
      content: content,
      actions: [
        if (cancelLabel != null)
          TextButton(
            onPressed: onCancel ?? () => Navigator.of(context).pop(),
            child: Text(cancelLabel!),
          ),
        if (confirmLabel != null)
          FilledButton(
            onPressed: onConfirm,
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  )
                : null,
            child: Text(confirmLabel!),
          ),
      ],
    );
  }
}
