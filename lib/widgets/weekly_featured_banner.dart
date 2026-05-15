import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cosmetic_item.dart';
import '../models/weekly_featured_cosmetic.dart';
import '../services/cosmetics_service.dart';
import '../state/avatar_provider.dart';
import '../state/weekly_featured_provider.dart';
import 'cosmetic_visuals.dart';
import 'weekly_featured_flair_chip.dart';

class WeeklyFeaturedBanner extends StatefulWidget {
  const WeeklyFeaturedBanner({
    super.key,
    this.set,
    this.completed,
    this.now,
    this.compact = false,
    this.showItemSilhouettes = true,
    this.margin = EdgeInsets.zero,
  });

  final WeeklyFeaturedCosmeticSet? set;
  final bool? completed;
  final DateTime? now;
  final bool compact;
  final bool showItemSilhouettes;
  final EdgeInsetsGeometry margin;

  @override
  State<WeeklyFeaturedBanner> createState() => _WeeklyFeaturedBannerState();
}

class _WeeklyFeaturedBannerState extends State<WeeklyFeaturedBanner> {
  @override
  Widget build(BuildContext context) {
    final provider = _maybeWatch<WeeklyFeaturedProvider>(context);
    final avatar = _maybeWatch<AvatarProvider>(context);
    final set = widget.set ?? provider?.activeSet;
    if (set == null) return const SizedBox.shrink();

    if (provider != null && avatar != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        provider.refreshCompletionFromInventory(avatar.inventory);
      });
    }

    final now = widget.now ?? DateTime.now();
    final catalog = CosmeticsService.instance.getCatalog();
    final headline = set.resolveHeadline(catalog);
    final items = set.resolveItems(catalog);
    final completed = widget.completed ?? provider?.completedActiveSet ?? false;
    final headlineColor = CosmeticVisuals.rarityColor(
      headline?.rarity ?? CosmeticRarity.rare,
    );
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const Key('weekly_featured_banner'),
      width: double.infinity,
      margin: widget.margin,
      padding: EdgeInsets.all(widget.compact ? 10 : 14),
      decoration: BoxDecoration(
        color: headlineColor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(widget.compact ? 14 : 16),
        border: Border.all(color: headlineColor.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: headlineColor.withValues(alpha: 0.10),
            blurRadius: widget.compact ? 10 : 16,
          ),
        ],
      ),
      child: Row(
        children: [
          _HeadlineBadge(item: headline, color: headlineColor),
          SizedBox(width: widget.compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        set.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: headlineColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CountdownPill(label: set.countdownLabel(now)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  set.urgencyLabel(now),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!widget.compact && headline != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Featured: ${headline.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (widget.showItemSilhouettes && items.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _FeaturedSilhouettes(items: items),
                ],
                if (completed) ...[
                  const SizedBox(height: 8),
                  WeeklyFeaturedFlairChip(
                    label: set.badgeName,
                    compact: widget.compact,
                    maxWidth: 210,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  T? _maybeWatch<T>(BuildContext context) {
    try {
      return context.watch<T>();
    } catch (_) {
      return null;
    }
  }
}

class _HeadlineBadge extends StatelessWidget {
  const _HeadlineBadge({required this.item, required this.color});

  final CosmeticItem? item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 12),
        ],
      ),
      child: Icon(_iconForItem(item), color: color, size: 25),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('weekly_featured_countdown'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FeaturedSilhouettes extends StatelessWidget {
  const _FeaturedSilhouettes({required this.items});

  final List<CosmeticItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: items
          .take(5)
          .map((item) {
            final color = CosmeticVisuals.rarityColor(item.rarity);
            return Tooltip(
              message: item.name,
              child: Container(
                key: ValueKey<String>('weekly_featured_item_${item.id}'),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Icon(_iconForItem(item), size: 15, color: color),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

IconData _iconForItem(CosmeticItem? item) {
  if (item == null) return Icons.auto_awesome_rounded;
  return switch (item.category) {
    CosmeticCategory.avatarFrame => Icons.hexagon_outlined,
    CosmeticCategory.animatedEffect =>
      item.id.contains('trail')
          ? Icons.timeline_rounded
          : Icons.auto_awesome_rounded,
    CosmeticCategory.profileBackground => Icons.wallpaper_rounded,
    CosmeticCategory.accessory => Icons.workspace_premium_rounded,
    CosmeticCategory.avatarSkin => Icons.face_rounded,
    CosmeticCategory.hairStyle => Icons.auto_awesome_rounded,
    CosmeticCategory.clothing => Icons.checkroom_rounded,
    CosmeticCategory.emojiReaction => Icons.emoji_emotions_rounded,
    _ => Icons.stars_rounded,
  };
}
