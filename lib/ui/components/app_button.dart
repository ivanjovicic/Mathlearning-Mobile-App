import 'package:flutter/material.dart';

import '../../theme/app_scale.dart';
import '../../theme/theme_extensions/theme_context.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final AppButtonVariant variant;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final radius = BorderRadius.circular(context.radius.pill);
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon!,
              SizedBox(width: context.spacing.s),
              Text(label),
            ],
          );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: Size.fromHeight(AppScale.s(48)),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );
        break;
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(AppScale.s(48)),
            foregroundColor: theme.colorScheme.onSurface,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );
        break;
      case AppButtonVariant.ghost:
        button = TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size.fromHeight(AppScale.s(48)),
            foregroundColor: theme.colorScheme.onSurface,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: child,
        );
        break;
    }

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
