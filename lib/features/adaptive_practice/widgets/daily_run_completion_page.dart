import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/widgets/daily_chest.dart';
import 'package:mathlearning/state/daily_run_provider.dart';

class DailyRunCompletionPage extends StatelessWidget {
  const DailyRunCompletionPage({super.key, required this.onOpenChest});

  final VoidCallback onOpenChest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primaryContainer, colors.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                Text(
                      'Run cleared!',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 220.ms)
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                      duration: 320.ms,
                    ),
                const SizedBox(height: 10),
                Text(
                  'Clear the gates. Keep the streak alive. Crack the chest.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ).animate(delay: 140.ms).fadeIn(duration: 240.ms),
                const SizedBox(height: 32),
                DailyChest(
                      state: DailyChestState.ready,
                      onTap: null,
                      pulseOnce: true,
                      size: 118,
                    )
                    .animate(delay: 280.ms)
                    .slideY(
                      begin: -0.55,
                      end: 0,
                      duration: 520.ms,
                      curve: Curves.bounceOut,
                    )
                    .fadeIn(duration: 180.ms),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onOpenChest,
                    icon: const Icon(Icons.card_giftcard_rounded),
                    label: const Text('Open your chest'),
                  ),
                ).animate(delay: 640.ms).fadeIn(duration: 220.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
