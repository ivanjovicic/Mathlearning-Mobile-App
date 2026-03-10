import 'package:flutter/material.dart';

import '../../theme/theme_extensions/theme_context.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.s,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.cardBackground,
        borderRadius: BorderRadius.circular(context.radius.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: context.spacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor ?? colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
