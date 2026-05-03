import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/widgets/daily_chest.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/widgets/xp_animation.dart';

class DailyChestRewardSheet extends StatefulWidget {
  const DailyChestRewardSheet({
    super.key,
    required this.reward,
    required this.onContinue,
  });

  final DailyChestReward reward;
  final VoidCallback onContinue;

  @override
  State<DailyChestRewardSheet> createState() => _DailyChestRewardSheetState();
}

class _DailyChestRewardSheetState extends State<DailyChestRewardSheet> {
  int _visibleRewardCount = 0;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    for (var index = 1; index <= 3; index++) {
      _timers.add(
        Timer(Duration(milliseconds: 260 * index), () {
          if (!mounted) {
            return;
          }
          setState(() => _visibleRewardCount = index);
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily reward ready!',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crack the chest',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Center(child: XPAnimation(xp: widget.reward.xp)),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey<int>(_visibleRewardCount),
                children: [
                  if (_visibleRewardCount >= 1)
                    _RewardRow(
                      icon: Icons.bolt_rounded,
                      label: '+${widget.reward.xp} XP',
                      color: colors.primary,
                    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.12),
                  if (_visibleRewardCount >= 2) ...[
                    const SizedBox(height: 8),
                    _RewardRow(
                      icon: Icons.monetization_on_rounded,
                      label: '+${widget.reward.coins} coins',
                      color: colors.secondary,
                    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.12),
                  ],
                  if (_visibleRewardCount >= 3) ...[
                    const SizedBox(height: 8),
                    _RewardRow(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Cosmetic fragment found',
                      subtitle: widget.reward.cosmeticFragment,
                      color: colors.tertiary,
                    ).animate().fadeIn(duration: 180.ms).slideY(begin: 0.12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  DailyChest(
                    state: DailyChestState.locked,
                    onTap: null,
                    size: 42,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tomorrow',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Tomorrow\'s chest is even better 👀',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Come back tomorrow for a new one!',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onContinue,
                child: const Text('Nice!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.label,
    required this.color,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
