import 'package:flutter/material.dart';

import '../models/cosmetic_item.dart';
import 'cosmetic_visuals.dart';

/// A card widget that displays a single cosmetic item in the inventory gallery.
class CosmeticItemCard extends StatelessWidget {
  const CosmeticItemCard({
    super.key,
    required this.item,
    required this.isOwned,
    required this.isEquipped,
    this.onTap,
  });

  final CosmeticItem item;
  final bool isOwned;
  final bool isEquipped;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rarityColor = CosmeticVisuals.rarityColor(item.rarity);
    final gradient = CosmeticVisuals.rarityGradient(item.rarity);

    return GestureDetector(
      onTap: isOwned ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isEquipped ? gradient : null,
          color: isEquipped && gradient == null ? rarityColor : null,
            border: Border.all(
            color: isEquipped
                ? rarityColor
                : isOwned
                    ? rarityColor.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.2),
            width: isEquipped ? 2.5 : 1.5,
          ),
          boxShadow: isEquipped
              ? [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: isOwned
                      ? rarityColor.withValues(alpha: isEquipped ? 0.15 : 0.08)
                      : Colors.grey.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon / Emoji
                  Expanded(
                    child: Center(
                      child: ColorFiltered(
                        colorFilter: isOwned
                            ? const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.multiply,
                              )
                            : const ColorFilter.matrix([
                                0.3, 0.3, 0.3, 0, 0,
                                0.3, 0.3, 0.3, 0, 0,
                                0.3, 0.3, 0.3, 0, 0,
                                0, 0, 0, 0.8, 0,
                              ]),
                        child: _ItemIcon(item: item, rarityColor: rarityColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Name
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isEquipped ? FontWeight.bold : FontWeight.w500,
                      color: isOwned
                          ? (isEquipped ? Colors.white : null)
                          : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Rarity indicator (top-left dot)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rarityColor,
                ),
              ),
            ),

            // Equipped checkmark
            if (isEquipped)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rarityColor,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),

            // Locked overlay
            if (!isOwned)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Icon rendering ──────────────────────────────────────────────────────────

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.item, required this.rarityColor});

  final CosmeticItem item;
  final Color rarityColor;

  @override
  Widget build(BuildContext context) {
    final key = item.assetKey;

    // Emoji reaction items use their emoji directly
    if (item.category == CosmeticCategory.emojiReaction) {
      return Text(key, style: const TextStyle(fontSize: 28));
    }

    // For framework items, use Icons
    return Icon(_iconForItem(item), color: rarityColor, size: 32);
  }

  IconData _iconForItem(CosmeticItem item) {
    switch (item.category) {
      case CosmeticCategory.avatarSkin:
        return Icons.face;
      case CosmeticCategory.hairStyle:
        return Icons.auto_awesome;
      case CosmeticCategory.clothing:
        return Icons.checkroom;
      case CosmeticCategory.accessory:
        return Icons.diamond_outlined;
      case CosmeticCategory.avatarFrame:
        return Icons.crop_square;
      case CosmeticCategory.profileBackground:
        return Icons.wallpaper;
      case CosmeticCategory.profileBadge:
        return Icons.verified;
      case CosmeticCategory.reactionSticker:
        return Icons.emoji_emotions;
      case CosmeticCategory.animatedEffect:
        return Icons.auto_fix_high;
      default:
        return Icons.star;
    }
  }
}
