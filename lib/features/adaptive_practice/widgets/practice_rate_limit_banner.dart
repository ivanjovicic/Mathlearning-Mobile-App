import 'package:flutter/material.dart';

class PracticeRateLimitBanner extends StatelessWidget {
  const PracticeRateLimitBanner({super.key, required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    if (remaining <= Duration.zero) {
      return const SizedBox.shrink();
    }
    final seconds = remaining.inSeconds.clamp(1, 3600);
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hold on — try again in ${seconds}s! ⏳',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
