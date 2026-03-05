import 'package:flutter/material.dart';

/// Horizontal row showing XP reward and estimated duration for a node.
class NodeRewardRow extends StatelessWidget {
  final int xpReward;
  final int estimatedMinutes;

  const NodeRewardRow({
    super.key,
    required this.xpReward,
    required this.estimatedMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        _Chip(
          icon: Icons.star_rounded,
          label: '+$xpReward XP',
          color: const Color(0xFFFFB800),
        ),
        const SizedBox(width: 8),
        _Chip(
          icon: Icons.timer_outlined,
          label: '~$estimatedMinutes min',
          color: cs.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
