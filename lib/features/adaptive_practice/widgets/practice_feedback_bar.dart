import 'package:flutter/material.dart';

class PracticeFeedbackBar extends StatelessWidget {
  const PracticeFeedbackBar({
    super.key,
    required this.feedback,
    required this.isCorrect,
  });

  final String? feedback;
  final bool? isCorrect;

  @override
  Widget build(BuildContext context) {
    if (feedback == null || feedback!.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final bool positive = isCorrect == true;
    final background = positive
        ? Colors.green.withValues(alpha: 0.12)
        : colorScheme.errorContainer.withValues(alpha: 0.7);
    final foreground = positive
        ? Colors.green.shade700
        : colorScheme.onErrorContainer;
    final icon = positive ? Icons.check_circle : Icons.info_outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feedback!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
