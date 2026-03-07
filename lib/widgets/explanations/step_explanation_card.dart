import 'package:flutter/material.dart';

import '../../models/step_explanation.dart';
import 'hint_widget.dart';
import 'math_formula_view.dart';

class StepExplanationCard extends StatelessWidget {
  const StepExplanationCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.isHintVisible,
    required this.onHintToggle,
    this.semanticPrefix = 'Step explanation',
  });

  final StepExplanation step;
  final int stepNumber;
  final int totalSteps;
  final bool isHintVisible;
  final VoidCallback onHintToggle;
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showHintButton = (step.hint?.trim().isNotEmpty ?? false);
    final isFormulaStep = _looksLikeFormula(step.text);

    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: '$semanticPrefix: Step $stepNumber of $totalSteps. ${step.text}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: step.highlight
                  ? cs.tertiary.withValues(alpha: 0.85)
                  : cs.outline.withValues(alpha: 0.4),
              width: step.highlight ? 1.8 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: step.highlight
                    ? cs.tertiary.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: step.highlight ? 18 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primaryContainer,
                    ),
                    child: Text(
                      '$stepNumber',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Step $stepNumber',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (step.highlight)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 15,
                            color: cs.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Important',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: cs.onTertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                step.text,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              if (isFormulaStep) ...[
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    key: ValueKey<bool>(step.highlight),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: step.highlight
                          ? cs.primaryContainer.withValues(alpha: 0.6)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: MathFormulaView(
                      expression: step.text,
                      center: true,
                      semanticLabel: 'Step $stepNumber formula: ${step.text}',
                      textStyle: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
              if (showHintButton) ...[
                const SizedBox(height: 12),
                HintWidget(
                  hintText: step.hint!.trim(),
                  isVisible: isHintVisible,
                  onToggle: onHintToggle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _looksLikeFormula(String input) {
    final value = input.trim();
    if (value.isEmpty) return false;
    if (value.contains(r'\') ||
        value.contains('=') ||
        value.contains('√') ||
        value.contains('^')) {
      return true;
    }
    return RegExp(r'\d').hasMatch(value) &&
        RegExp(r'[+\-*/()]').hasMatch(value);
  }
}
