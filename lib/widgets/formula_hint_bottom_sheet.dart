import 'package:flutter/material.dart';

import '../l10n/app_i18n.dart';
import '../models/step_explanation.dart';
import 'explanations/step_explanation_controller.dart';
import 'explanations/step_explanation_list.dart';

class FormulaHintBottomSheet extends StatefulWidget {
  const FormulaHintBottomSheet({
    super.key,
    this.formula,
    this.steps,
    this.onClose,
  }) : assert(
         formula != null || (steps != null && steps.length > 0),
         'Provide formula or non-empty steps.',
       );

  final String? formula;
  final List<StepExplanation>? steps;
  final VoidCallback? onClose;

  static Future<void> show(BuildContext context, String formula) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (_) => FormulaHintBottomSheet(formula: formula),
    );
  }

  static Future<void> showSteps(
    BuildContext context,
    List<StepExplanation> steps,
  ) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface.withValues(alpha: 0),
      isScrollControlled: true,
      builder: (_) => FormulaHintBottomSheet(steps: steps),
    );
  }

  @override
  State<FormulaHintBottomSheet> createState() => _FormulaHintBottomSheetState();
}

class _FormulaHintBottomSheetState extends State<FormulaHintBottomSheet> {
  late final List<StepExplanation> _steps;
  late final StepExplanationController _controller;

  @override
  void initState() {
    super.initState();

    final provided = widget.steps;
    if (provided != null && provided.isNotEmpty) {
      _steps = provided.where((s) => s.text.trim().isNotEmpty).toList();
    } else {
      final formula = widget.formula ?? '';
      _steps = _extractSteps(
        formula,
      ).map((line) => StepExplanation(text: line)).toList();
    }

    if (_steps.isEmpty) {
      _steps.add(StepExplanation(text: widget.formula?.trim() ?? '?'));
    }

    _controller = StepExplanationController(steps: _steps);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.34),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.lightbulb, color: cs.secondary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.formulaHintTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      widget.onClose?.call();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                t.formulaHintSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StepExplanationList(
                  controller: _controller,
                  steps: _steps,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(t.gotIt),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
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
