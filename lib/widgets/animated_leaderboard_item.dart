import 'package:flutter/material.dart';

import '../models/leaderboard_models.dart';
import '../models/cosmetic_target.dart';
import '../models/social_cosmetic_loadout.dart';
import '../services/cosmetics_service.dart';
import '../theme/app_scale.dart';
import 'cosmetic_visuals.dart';
import '../models/player_identity.dart';
import 'cosmetic_flex_chip.dart';
import 'cosmetic_target_chip.dart';
import 'player_title_chip.dart';
import 'social_cosmetic_avatar.dart';
import 'weekly_featured_flair_chip.dart';

class AnimatedLeaderboardItem extends StatelessWidget {
  final LeaderboardItem item;
  final bool isCurrentUser;
  final int previousRank;
  final String? title;
  final String? subtitle;
  final SocialCosmeticLoadout? currentUserLoadout;
  final CosmeticTarget? currentUserTarget;
  final String? weeklyFeaturedCompletionLabel;
  final PlayerTitle? playerTitle;

  const AnimatedLeaderboardItem({
    super.key,
    required this.item,
    this.isCurrentUser = false,
    this.previousRank = 0,
    this.title,
    this.subtitle,
    this.currentUserLoadout,
    this.currentUserTarget,
    this.weeklyFeaturedCompletionLabel,
    this.playerTitle,
  });

  @override
  Widget build(BuildContext context) {
    final loadout =
        isCurrentUser && currentUserLoadout?.hasEquippedCosmetics == true
        ? currentUserLoadout!
        : item.cosmeticLoadout ?? const SocialCosmeticLoadout();

    final hasCosmetic = loadout.hasEquippedCosmetics;
    final flexItem = loadout.flexItemWithCatalog(
      CosmeticsService.instance.getCatalog(),
    );
    final accentColor = flexItem == null
        ? null
        : CosmeticVisuals.rarityColor(flexItem.rarity);
    final target = isCurrentUser && currentUserTarget != null
        ? currentUserTarget
        : null;
    final weeklyLabel = isCurrentUser ? weeklyFeaturedCompletionLabel : null;
    final weeklyAccent = weeklyLabel == null
        ? null
        : Theme.of(context).colorScheme.tertiary;
    final rowAccentColor = accentColor ?? weeklyAccent;
    final hasRowAccent = hasCosmetic || weeklyLabel != null;

    return Container(
      key: weeklyLabel != null
          ? const Key('leaderboard_weekly_featured_accent')
          : hasCosmetic
          ? const Key('leaderboard_cosmetic_accent')
          : null,
      margin: EdgeInsets.symmetric(vertical: AppScale.s(2)),
      decoration: hasRowAccent && rowAccentColor != null
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(AppScale.s(12)),
              border: Border.all(
                color: rowAccentColor.withValues(alpha: 0.34),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: rowAccentColor.withValues(alpha: 0.08),
                  blurRadius: AppScale.s(10),
                  spreadRadius: 0,
                ),
              ],
            )
          : null,
      child: ListTile(
        leading: SizedBox(
          width: 96,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 17, child: Text('${item.rank}')),
              const SizedBox(width: 8),
              SocialCosmeticAvatar(
                userId: item.userId.toString(),
                displayName: item.displayName,
                avatarUrl: item.avatarUrl,
                loadout: loadout,
                size: 46,
                isCurrentUser: isCurrentUser,
              ),
            ],
          ),
        ),
        title: Text(title ?? item.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subtitle ?? 'Score: ${item.score}'),
            if (hasCosmetic)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: CosmeticFlexChip(
                  loadout: loadout,
                  isCurrentUser: isCurrentUser,
                  compact: true,
                  maxWidth: 150,
                ),
              ),
            if (target != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: CosmeticTargetChip(
                  target: target,
                  compact: true,
                  maxWidth: 150,
                ),
              ),
            if (weeklyLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: WeeklyFeaturedFlairChip(
                  label: weeklyLabel,
                  compact: true,
                  maxWidth: 160,
                ),
              ),
            if (isCurrentUser && playerTitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: PlayerTitleChip(title: playerTitle, compact: true),
              ),
          ],
        ),
        trailing: isCurrentUser ? const Text('Ti') : null,
      ),
    );
  }
}
