import 'package:flutter/material.dart';

import '../../theme/theme_extensions/theme_context.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radius;
    final content = Container(
      padding: padding ?? EdgeInsets.all(context.spacing.m),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.cardBackground,
        borderRadius: BorderRadius.circular(radius.card),
        border: Border.all(color: borderColor ?? colors.border),
        boxShadow: context.shadows.cardShadow,
      ),
      child: child,
    );

    return Container(
      margin: margin,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius.card),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}
