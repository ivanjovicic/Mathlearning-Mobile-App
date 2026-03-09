import 'package:flutter/material.dart';

import '../../theme/app_scale.dart';
import '../../theme/theme_extensions/theme_context.dart';

class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.text,
    required this.selected,
    this.correct = false,
    this.wrong = false,
    this.enabled = true,
    this.onTap,
  });

  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spacing = context.spacing;
    final radius = context.radius;
    final motion = context.motion;
    final bgColor = correct
        ? cs.tertiaryContainer
        : wrong
        ? cs.errorContainer
        : selected
        ? cs.primaryContainer
        : context.colors.cardBackground;
    final borderColor = correct
        ? cs.tertiary
        : wrong
        ? cs.error
        : selected
        ? cs.primary
        : context.colors.border;

    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(radius.large),
        child: AnimatedContainer(
          duration: motion.fast,
          curve: motion.standard,
          constraints: BoxConstraints(minHeight: AppScale.s(48)),
          padding: EdgeInsets.symmetric(
            horizontal: spacing.m,
            vertical: spacing.s + spacing.xs / 2,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(radius.large),
            border: Border.all(
              color: borderColor,
              width: selected ? AppScale.s(1.6) : AppScale.s(1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnswerOptionCard extends QuizOptionTile {
  const AnswerOptionCard({
    super.key,
    required super.text,
    required super.selected,
    super.correct = false,
    super.wrong = false,
    super.enabled = true,
    super.onTap,
  });
}
