import 'package:flutter/material.dart';

import '../math_content_text.dart';
import 'step_explanation_controller.dart';

class MistakeExplanationCard extends StatelessWidget {
  const MistakeExplanationCard({
    super.key,
    required this.explanation,
    this.misconception,
    this.mistakeType = MistakeType.unknown,
    this.studentAnswer,
    this.expectedAnswer,
  });

  final String explanation;
  final String? misconception;
  final MistakeType mistakeType;
  final String? studentAnswer;
  final String? expectedAnswer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label:
          'Why your answer was incorrect. ${_titleForType(mistakeType)}. $explanation',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.error.withValues(alpha: 0.72),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Why your answer was incorrect',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _titleForType(mistakeType),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            MathContentText(
              value: explanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onErrorContainer,
                height: 1.4,
              ),
            ),
            if (misconception != null && misconception!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              MathContentText(
                value: 'Common misconception: ${misconception!.trim()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onErrorContainer.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if ((studentAnswer?.trim().isNotEmpty ?? false) ||
                (expectedAnswer?.trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (studentAnswer?.trim().isNotEmpty ?? false)
                    _pill(
                      context,
                      label: 'Your answer: ${studentAnswer!.trim()}',
                    ),
                  if (expectedAnswer?.trim().isNotEmpty ?? false)
                    _pill(
                      context,
                      label: 'Expected: ${expectedAnswer!.trim()}',
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, {required String label}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: MathContentText(
        value: label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _titleForType(MistakeType type) {
    switch (type) {
      case MistakeType.signError:
        return 'Possible sign error (+/-).';
      case MistakeType.denominatorError:
        return 'Possible denominator handling mistake.';
      case MistakeType.orderOfOperations:
        return 'Possible order-of-operations mistake.';
      case MistakeType.unknown:
        return 'Let us review this step carefully.';
    }
  }
}
