import 'package:flutter/material.dart';

import '../models/cosmetic_item.dart';
import '../models/social_cosmetic_loadout.dart';
import '../models/user_avatar.dart';
import '../services/new_look_badge_service.dart';
import 'avatar_widget.dart';
import 'cosmetic_visuals.dart';

class SocialCosmeticAvatar extends StatelessWidget {
  const SocialCosmeticAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.loadout,
    this.size = 44,
    this.showRecentBadge = true,
    this.isCurrentUser = false,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final SocialCosmeticLoadout? loadout;
  final double size;
  final bool showRecentBadge;
  /// When true, checks SharedPreferences for a recent equip and shows a
  /// "NEW" badge for up to 24 hours after the user last changed their look.
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final effectiveLoadout = loadout;
    final rarity = effectiveLoadout?.strongestRarity;
    final glowColor = rarity == null || rarity == CosmeticRarity.common
        ? null
        : CosmeticVisuals.rarityColor(rarity);
    final avatarConfig = effectiveLoadout?.hasEquippedCosmetics == true
        ? effectiveLoadout!.toAvatarConfig(userId)
        : null;

    Widget avatar = avatarUrl == null
        ? AvatarWidget(
            size: size,
            showFrame: true,
            overrideConfig: avatarConfig ?? UserAvatar.defaults(userId),
            borderColor: glowColor,
          )
        : _NetworkAvatar(
            size: size,
            avatarUrl: avatarUrl!,
            displayName: displayName,
            frameId: effectiveLoadout?.avatarFrameId,
            glowColor: glowColor,
          );

    if (effectiveLoadout?.animatedEffectId != null && avatarUrl != null) {
      avatar = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatar,
          Positioned(
            right: -size * 0.08,
            bottom: size * 0.02,
            child: _EffectDot(
              size: size * 0.28,
              effectId: effectiveLoadout!.animatedEffectId,
            ),
          ),
        ],
      );
    }

    if (showRecentBadge && effectiveLoadout?.hasRecentRareUnlock == true) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -size * 0.14,
            top: -size * 0.12,
            child: _RecentUnlockBadge(rarity: rarity ?? CosmeticRarity.rare),
          ),
        ],
      );
    }

    if (isCurrentUser) {
      avatar = _NewLookBadgeOverlay(size: size, child: avatar);
    }

    return Semantics(
      label: effectiveLoadout?.isEmpty == false
          ? '$displayName equipped cosmetics'
          : '$displayName default avatar',
      child: avatar,
    );
  }
}

class _NetworkAvatar extends StatelessWidget {
  const _NetworkAvatar({
    required this.size,
    required this.avatarUrl,
    required this.displayName,
    this.frameId,
    this.glowColor,
  });

  final double size;
  final String avatarUrl;
  final String displayName;
  final String? frameId;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: frameId != null
          ? CosmeticVisuals.frameDecoration(frameId, size)
          : BoxDecoration(
              shape: BoxShape.circle,
              border: glowColor == null
                  ? null
                  : Border.all(color: glowColor!, width: size * 0.04),
              boxShadow: glowColor == null
                  ? null
                  : [
                      BoxShadow(
                        color: glowColor!.withValues(alpha: 0.35),
                        blurRadius: size * 0.28,
                        spreadRadius: size * 0.02,
                      ),
                    ],
            ),
      child: CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, _) {},
        child: displayName.isEmpty ? const Icon(Icons.person) : null,
      ),
    );
  }
}

class _EffectDot extends StatelessWidget {
  const _EffectDot({required this.size, required this.effectId});

  final double size;
  final String? effectId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00E5FF),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
            blurRadius: size * 0.65,
          ),
        ],
      ),
      child: Icon(
        CosmeticVisuals.animatedEffectIcon(effectId),
        size: size * 0.62,
        color: Colors.white,
      ),
    );
  }
}

/// Overlays a small "✦ NEW" chip in the top-right corner when the current
/// user has equipped a cosmetic within the last 24 hours.
class _NewLookBadgeOverlay extends StatefulWidget {
  const _NewLookBadgeOverlay({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  State<_NewLookBadgeOverlay> createState() => _NewLookBadgeOverlayState();
}

class _NewLookBadgeOverlayState extends State<_NewLookBadgeOverlay> {
  late final Future<bool> _activeFuture;

  @override
  void initState() {
    super.initState();
    _activeFuture = NewLookBadgeService.instance.isActive();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _activeFuture,
      builder: (context, snapshot) {
        final showBadge = snapshot.data == true;
        if (!showBadge) return widget.child;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned(
              left: -widget.size * 0.12,
              top: -widget.size * 0.18,
              child: _NewLookChip(fontSize: widget.size * 0.22),
            ),
          ],
        );
      },
    );
  }
}

class _NewLookChip extends StatelessWidget {
  const _NewLookChip({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        '✦ NEW',
        style: TextStyle(
          color: colors.onPrimary,
          fontWeight: FontWeight.w900,
          fontSize: fontSize.clamp(8.0, 12.0),
          letterSpacing: 0.3,
          height: 1,
        ),
      ),
    );
  }
}

class _RecentUnlockBadge extends StatelessWidget {
  const _RecentUnlockBadge({required this.rarity});

  final CosmeticRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = CosmeticVisuals.rarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 9,
        ),
      ),
    );
  }
}

class RecentUnlocksStrip extends StatelessWidget {
  const RecentUnlocksStrip({
    super.key,
    required this.unlocks,
    this.emptyText = 'No cosmetic unlocks yet.',
  });

  final List<SocialCosmeticUnlock> unlocks;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    if (unlocks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Text(
          emptyText,
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: unlocks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final unlock = unlocks[index];
          final color = CosmeticVisuals.rarityColor(unlock.rarity);
          return Container(
            width: 126,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(_unlockIcon(unlock.itemId), color: color, size: 22),
                Text(
                  unlock.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  unlock.rarity.label,
                  style: textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _unlockIcon(String itemId) {
    if (itemId.startsWith('frame_')) return Icons.hexagon_outlined;
    if (itemId.startsWith('effect_')) return Icons.auto_awesome;
    if (itemId.startsWith('acc_')) return Icons.workspace_premium;
    return Icons.stars;
  }
}
