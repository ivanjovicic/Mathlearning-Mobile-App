import 'package:flutter/material.dart';

import '../../theme/app_scale.dart';
import '../../theme/theme_extensions/theme_context.dart';

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? context.colors.textPrimary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.s,
        vertical: context.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.cardBackground,
        borderRadius: BorderRadius.circular(context.radius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppScale.icon(14, min: 12, max: 18), color: fg),
            SizedBox(width: context.spacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
