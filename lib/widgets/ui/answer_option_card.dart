import 'package:flutter/material.dart';

class AnswerOptionCard extends StatelessWidget {
  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final bool enabled;
  final VoidCallback? onTap;

  const AnswerOptionCard({
    super.key,
    required this.text,
    required this.selected,
    this.correct = false,
    this.wrong = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = correct
        ? cs.tertiaryContainer
        : wrong
        ? cs.errorContainer
        : selected
        ? cs.primaryContainer
        : cs.surfaceContainerHighest;
    final borderColor = correct
        ? cs.tertiary
        : wrong
        ? cs.error
        : selected
        ? cs.primary
        : cs.outlineVariant;

    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
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
