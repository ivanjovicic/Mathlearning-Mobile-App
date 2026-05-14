import 'package:flutter/material.dart';

import '../models/player_identity.dart';

/// A compact chip that displays a [PlayerTitle] badge.
/// Returns [SizedBox.shrink] when [titleId] is null.
class PlayerTitleChip extends StatelessWidget {
  const PlayerTitleChip({
    super.key,
    required this.title,
    this.compact = false,
  });

  /// The title to display. Pass null to render nothing.
  final PlayerTitle? title;

  /// When true, omits the unlock criteria tooltip text and renders smaller.
  final bool compact;

  static Color colorFor(PlayerTitle title) {
    switch (title) {
      case PlayerTitle.dailyRunMaster:
        return const Color(0xFF43A047); // green
      case PlayerTitle.streakKeeper:
        return const Color(0xFFFF7043); // deep orange
      case PlayerTitle.novaChampion:
        return const Color(0xFF7E57C2); // purple (epic)
      case PlayerTitle.legendaryUnlock:
        return const Color(0xFFFF9800); // orange (legendary)
      case PlayerTitle.seasonVeteran:
        return const Color(0xFF1E88E5); // blue
      case PlayerTitle.rareHunter:
        return const Color(0xFF00ACC1); // cyan
    }
  }

  static IconData iconFor(PlayerTitle title) {
    switch (title) {
      case PlayerTitle.dailyRunMaster:
        return Icons.directions_run_rounded;
      case PlayerTitle.streakKeeper:
        return Icons.local_fire_department_rounded;
      case PlayerTitle.novaChampion:
        return Icons.auto_awesome_rounded;
      case PlayerTitle.legendaryUnlock:
        return Icons.emoji_events_rounded;
      case PlayerTitle.seasonVeteran:
        return Icons.workspace_premium_rounded;
      case PlayerTitle.rareHunter:
        return Icons.diamond_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = title;
    if (t == null) {
      return const SizedBox.shrink(key: Key('player_title_chip_empty'));
    }

    final color = colorFor(t);
    final iconSize = compact ? 12.0 : 14.0;
    final fontSize = compact ? 11.0 : 12.0;
    final hPad = compact ? 6.0 : 8.0;
    final vPad = compact ? 3.0 : 4.0;

    return Container(
      key: Key('player_title_chip_${t.name}'),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconFor(t), size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            t.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
