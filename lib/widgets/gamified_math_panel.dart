import 'package:flutter/material.dart';

import 'math/math_renderer.dart';
import 'math/math_view_mode.dart';

/// Helper widget for rendering question prompts in the gamified quiz flow.
class GamifiedMathPanel extends StatelessWidget {
  const GamifiedMathPanel({
    super.key,
    required this.formula,
    required this.title,
    required this.subtitle,
    this.icon = Icons.calculate_rounded,
    this.expressionTextStyle,
  });

  final String formula;
  final String title;
  final String subtitle;
  final IconData icon;
  final TextStyle? expressionTextStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.88),
            colorScheme.secondaryContainer.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: MathRenderer(
              value: formula,
              mode: MathViewMode.questionStem,
              style: expressionTextStyle,
            ),
          ),
        ],
      ),
    );
  }
}
