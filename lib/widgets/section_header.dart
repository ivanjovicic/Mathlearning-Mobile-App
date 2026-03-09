import 'package:flutter/material.dart';

import '../theme/app_scale.dart';
import '../theme/theme_extensions/theme_context.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const SectionHeader({super.key, required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Row(
      children: [
        if (icon != null)
          Icon(
            icon,
            size: AppScale.icon(20, min: 18, max: 24),
            color: context.colors.textSecondary,
          ),
        if (icon != null) SizedBox(width: spacing.s),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
