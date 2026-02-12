import 'package:flutter/material.dart';
import '../l10n/app_i18n.dart';
import '../models/step_explanation.dart';
import 'gamified_math_panel.dart';

class FormulaHintBottomSheet extends StatefulWidget {
  final String? formula;
  final List<StepExplanation>? steps;
  final VoidCallback? onClose;

  const FormulaHintBottomSheet({
    super.key,
    this.formula,
    this.steps,
    this.onClose,
  }) : assert(
         formula != null || (steps != null && steps.length > 0),
         'Provide formula or non-empty steps.',
       );

  static Future<void> show(BuildContext context, String formula) {
    final colorScheme = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (context) => FormulaHintBottomSheet(formula: formula),
    );
  }

  static Future<void> showSteps(
    BuildContext context,
    List<StepExplanation> steps,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (context) => FormulaHintBottomSheet(steps: steps),
    );
  }

  @override
  State<FormulaHintBottomSheet> createState() => _FormulaHintBottomSheetState();
}

class _FormulaHintBottomSheetState extends State<FormulaHintBottomSheet> {
  late final List<StepExplanation> _steps;
  int _visibleSteps = 1;

  @override
  void initState() {
    super.initState();

    final provided = widget.steps;
    if (provided != null && provided.isNotEmpty) {
      _steps = provided.where((s) => s.text.trim().isNotEmpty).toList();
    } else {
      final formula = widget.formula ?? '';
      _steps = _extractSteps(formula)
          .map((line) => StepExplanation(text: line))
          .toList();
    }

    if (_steps.isEmpty) {
      _steps.add(StepExplanation(text: widget.formula?.trim() ?? '?'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: colorScheme.secondary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      t.formulaHintTitle,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        }
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    t.formulaStepCounter(_visibleSteps, _steps.length),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _visibleSteps; i++) ...[
                  _buildStepCard(
                    context,
                    step: _steps[i],
                    stepIndex: i,
                    titleFallback: t.formulaHintTitle,
                    subtitleFallback: i == 0
                        ? t.formulaHintSubtitle
                        : t.showNextStep,
                  ),
                  if (i < _visibleSteps - 1) const SizedBox(height: 10),
                ],
                if (_visibleSteps < _steps.length) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _revealNextStep,
                          icon: const Icon(Icons.visibility_outlined),
                          label: Text(t.showNextStep),
                        ),
                      ),
                      if (_steps.length - _visibleSteps > 1) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: _revealAllSteps,
                            child: Text(t.showAllSteps),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.tertiary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 18,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.formulaBonusTip,
                          style: TextStyle(
                            color: colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.secondary,
                      foregroundColor: colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      t.gotIt,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required StepExplanation step,
    required int stepIndex,
    required String titleFallback,
    required String subtitleFallback,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isHighlighted = step.highlight;
    final subtitle = step.hint?.trim().isNotEmpty == true
        ? step.hint!.trim()
        : subtitleFallback;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.tertiary.withValues(alpha: 0.65)
              : colorScheme.outline.withValues(alpha: 0.4),
          width: isHighlighted ? 1.4 : 1.0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: colorScheme.tertiary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Column(
        children: [
          if (isHighlighted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Key step',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: GamifiedMathPanel(
              formula: step.text,
              title: '$titleFallback ${stepIndex + 1}',
              subtitle: subtitle,
            ),
          ),
        ],
      ),
    );
  }

  void _revealNextStep() {
    if (_visibleSteps >= _steps.length) return;
    setState(() {
      _visibleSteps++;
    });
  }

  void _revealAllSteps() {
    setState(() {
      _visibleSteps = _steps.length;
    });
  }

  List<String> _extractSteps(String rawFormula) {
    final normalized = rawFormula.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) return ['?'];

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length > 1) return lines;

    const separators = ['=>', '\\Rightarrow', '\\to', ';'];
    for (final separator in separators) {
      if (normalized.contains(separator)) {
        final parts = normalized
            .split(separator)
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
        if (parts.length > 1) return parts;
      }
    }

    return [normalized];
  }
}
