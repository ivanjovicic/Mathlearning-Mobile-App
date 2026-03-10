import 'package:flutter/material.dart';

import '../../models/step_explanation.dart';
import '../../theme/app_scale.dart';
import '../../theme/theme_extensions/theme_context.dart';
import '../math/math_content_parser.dart';
import '../math_content_text.dart';
import '../math/math_view_mode.dart';
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
    final colors = context.colors;
    final spacing = context.spacing;
    final radius = context.radius;
    final motion = context.motion;
    final showHintButton = (step.hint?.trim().isNotEmpty ?? false);
    final parsedStep = MathContentParser.parse(step.text);
    final isFormulaStep =
        parsedStep.hasDisplayMath ||
        (parsedStep.hasMath &&
            parsedStep.segments.where((segment) => segment.isMath).length ==
                1 &&
            parsedStep.segments
                .where((segment) => !segment.isMath)
                .every((segment) => segment.value.trim().isEmpty));

    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: '$semanticPrefix: Step $stepNumber of $totalSteps. ${step.text}',
        child: AnimatedContainer(
          duration: motion.normal,
          curve: motion.standard,
          padding: EdgeInsets.all(spacing.m),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(radius.card),
            border: Border.all(
              color: step.highlight
                  ? cs.tertiary.withValues(alpha: 0.85)
                  : colors.border.withValues(alpha: 0.7),
              width: step.highlight ? AppScale.s(1.8) : AppScale.s(1.1),
            ),
            boxShadow: step.highlight
                ? context.shadows.focusShadow(cs.tertiary)
                : context.shadows.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppScale.s(34),
                    height: AppScale.s(34),
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
                  SizedBox(width: spacing.s),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: AppScale.s(10),
                        vertical: AppScale.s(6),
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(
                          AppScale.radius(999),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: AppScale.icon(15, min: 14, max: 22),
                            color: cs.onTertiaryContainer,
                          ),
                          SizedBox(width: spacing.xs),
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
              SizedBox(height: spacing.s + spacing.xs),
              MathContentText(
                value: step.text,
                mode: MathViewMode.explanationStep,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              if (isFormulaStep) ...[
                SizedBox(height: spacing.s + spacing.xs),
                AnimatedSwitcher(
                  duration: motion.fast,
                  child: Container(
                    key: ValueKey<bool>(step.highlight),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.m,
                      vertical: spacing.s + spacing.xs / 2,
                    ),
                    decoration: BoxDecoration(
                      color: step.highlight
                          ? cs.primaryContainer.withValues(alpha: 0.6)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(radius.medium),
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
                SizedBox(height: spacing.s),
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
}
