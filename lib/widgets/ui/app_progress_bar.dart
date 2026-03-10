import 'package:flutter/material.dart';

import '../../theme/app_scale.dart';
import '../../theme/theme_extensions/theme_context.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
  });

  final double value;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final clamped = value.clamp(0.0, 1.0);

    return Container(
      height: height ?? AppScale.s(10),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(context.radius.pill),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: foregroundColor ?? Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(context.radius.pill),
          ),
        ),
      ),
    );
  }
}
