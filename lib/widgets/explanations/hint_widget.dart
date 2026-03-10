import 'package:flutter/material.dart';

import '../math_content_text.dart';
import '../math/math_view_mode.dart';

class HintWidget extends StatelessWidget {
  const HintWidget({
    super.key,
    required this.hintText,
    required this.isVisible,
    required this.onToggle,
  });

  final String hintText;
  final bool isVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: isVisible ? 'Hide hint' : 'Show hint',
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onToggle,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  key: ValueKey<bool>(isVisible),
                  size: 18,
                ),
              ),
              label: Text(isVisible ? 'Hide Hint' : 'Show Hint'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                alignment: Alignment.centerLeft,
                foregroundColor: cs.primary,
                side: BorderSide(color: cs.primary.withValues(alpha: 0.55)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: isVisible
                ? AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.secondary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: cs.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: MathContentText(
                            value: hintText,
                            mode: MathViewMode.hint,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: cs.onSecondaryContainer),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
