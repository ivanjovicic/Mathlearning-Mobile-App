import 'package:flutter/material.dart';

import '../models/social_cosmetic_loadout.dart';
import '../services/cosmetics_service.dart';
import '../theme/app_scale.dart';
import 'cosmetic_detail_sheet.dart';
import 'cosmetic_visuals.dart';
import 'quick_chase_sheet.dart';

class CosmeticFlexChip extends StatelessWidget {
  const CosmeticFlexChip({
    super.key,
    required this.loadout,
    this.isCurrentUser = false,
    this.compact = false,
    this.showIcon = true,
    this.maxWidth,
  });

  final SocialCosmeticLoadout loadout;
  final bool isCurrentUser;
  final bool compact;
  final bool showIcon;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final item = loadout.flexItemWithCatalog(
      CosmeticsService.instance.getCatalog(),
    );
    if (item == null) return const SizedBox.shrink();

    final color = CosmeticVisuals.rarityColor(item.rarity);
    final child = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Material(
        color: color.withValues(alpha: compact ? 0.10 : 0.12),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => isCurrentUser
              ? showCosmeticDetailSheet(
                  context: context,
                  loadout: loadout,
                  item: item,
                  isCurrentUser: isCurrentUser,
                )
              : showQuickChaseSheet(
                  context: context,
                  item: item,
                ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : AppScale.s(8),
              vertical: compact ? 3 : AppScale.s(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon) ...[
                  Icon(
                    _iconFor(item.itemId),
                    size: compact ? 12 : 13,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 10 : AppScale.s(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Tooltip(message: '${item.rarity.label}: ${item.name}', child: child);
  }

  IconData _iconFor(String itemId) {
    if (itemId.startsWith('frame_')) return Icons.hexagon_outlined;
    if (itemId.startsWith('trail_')) return Icons.timeline;
    if (itemId.startsWith('effect_')) return Icons.auto_awesome;
    if (itemId.startsWith('acc_') || itemId.startsWith('gear_')) {
      return Icons.workspace_premium;
    }
    if (itemId.startsWith('bg_')) return Icons.wallpaper;
    return Icons.stars;
  }
}
