import 'package:flutter/material.dart';

import '../../../widgets/math/math_renderer.dart';
import '../../../widgets/math/math_view_mode.dart';

class PracticeOptionsList extends StatelessWidget {
  const PracticeOptionsList({
    super.key,
    required this.options,
    required this.enabled,
    required this.submitting,
    required this.onSelect,
    required this.lastSelected,
    required this.lastCorrect,
  });

  final List<String> options;
  final bool enabled;
  final bool submitting;
  final ValueChanged<String> onSelect;
  final String? lastSelected;
  final bool? lastCorrect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options
          .map((option) {
            final isSelected = lastSelected == option;
            Color? background;
            IconData? icon;
            if (submitting && isSelected && lastCorrect != null) {
              background = lastCorrect!
                  ? Colors.green.withValues(alpha: 0.14)
                  : Colors.red.withValues(alpha: 0.14);
              icon = lastCorrect! ? Icons.check_circle : Icons.error_outline;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                button: true,
                label: option,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: OutlinedButton.icon(
                    onPressed: enabled ? () => onSelect(option) : null,
                    icon: icon == null
                        ? const SizedBox.shrink()
                        : Icon(icon, size: 18),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    label: MathRenderer(
                      value: option,
                      mode: MathViewMode.answerOption,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
