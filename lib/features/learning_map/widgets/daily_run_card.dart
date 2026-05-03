import 'package:flutter/material.dart';

import 'package:mathlearning/features/learning_map/widgets/daily_chest.dart';
import 'package:mathlearning/state/daily_run_provider.dart';

class DailyRunCard extends StatelessWidget {
  const DailyRunCard({
    super.key,
    required this.isCompleted,
    required this.chestState,
    required this.onStart,
    required this.onOpenChest,
  });

  final bool isCompleted;
  final DailyChestState chestState;
  final VoidCallback onStart;
  final VoidCallback onOpenChest;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final subtitle = switch (chestState) {
      DailyChestState.locked => 'Finish it to unlock today\'s reward',
      DailyChestState.ready => 'Daily reward ready!',
      DailyChestState.opened => 'Come back tomorrow for a new one!',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Daily Run is ready',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onPrimaryContainer.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: _RunStepsRow()),
              const SizedBox(width: 10),
              Column(
                children: [
                  DailyChest(
                    state: chestState,
                    onTap: chestState == DailyChestState.ready
                        ? onOpenChest
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chestState == DailyChestState.ready
                        ? 'Open your chest'
                        : 'Daily Chest',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('daily_run_start_button'),
              onPressed: isCompleted ? null : onStart,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: Text(isCompleted ? 'Run Complete' : 'Start Run →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunStepsRow extends StatelessWidget {
  const _RunStepsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StepPill(label: 'Warm-up', icon: Icons.wb_sunny_outlined),
        _StepDivider(),
        _StepPill(label: 'Challenge', icon: Icons.bolt_rounded),
        _StepDivider(),
        _StepPill(label: 'Final Gate', icon: Icons.flag_rounded),
      ],
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: colors.onSurface),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: colors.onPrimaryContainer.withValues(alpha: 0.8),
      ),
    );
  }
}
