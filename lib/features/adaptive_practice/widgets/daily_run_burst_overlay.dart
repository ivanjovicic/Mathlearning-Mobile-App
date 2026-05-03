import 'package:flutter/material.dart';

import 'package:mathlearning/theme/app_scale.dart';

class DailyRunBurstOverlay extends StatelessWidget {
  const DailyRunBurstOverlay({
    super.key,
    required this.text,
    this.subtitle,
    this.icon,
    this.compact = false,
  });

  final String text;
  final String? subtitle;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final width = compact ? AppScale.s(230) : AppScale.s(280);

    return IgnorePointer(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
              reverseCurve: Curves.easeIn,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: curved, child: child),
            );
          },
          child: Container(
            key: ValueKey<String>('$text$subtitle'),
            width: width,
            padding: EdgeInsets.all(AppScale.s(compact ? 16 : 20)),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(AppScale.radius(22)),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.38),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: AppScale.s(24),
                  spreadRadius: AppScale.s(2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colors.primary, size: AppScale.icon(34)),
                  SizedBox(height: AppScale.s(8)),
                ],
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style:
                      (compact
                              ? textTheme.headlineSmall
                              : textTheme.displaySmall)
                          ?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w900,
                          ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppScale.s(6)),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
