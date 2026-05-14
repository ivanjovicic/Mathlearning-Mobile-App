import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/cosmetic_item.dart';
import '../models/cosmetic_target.dart';
import '../models/social_cosmetic_loadout.dart';
import '../navigation/navigation_extensions.dart';
import '../services/cosmetics_service.dart';
import '../state/cosmetic_target_provider.dart';
import '../state/season_provider.dart';
import '../theme/app_scale.dart';
import 'avatar_widget.dart';
import 'cosmetic_visuals.dart';
import 'quick_chase_sheet.dart';

class TargetCosmeticChaseCard extends StatelessWidget {
  const TargetCosmeticChaseCard({
    super.key,
    this.target,
    this.compact = false,
    this.margin = EdgeInsets.zero,
  });

  final CosmeticTarget? target;
  final bool compact;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final provider = _maybeWatch<CosmeticTargetProvider>(context);
    final activeTarget = target ?? provider?.target;
    if (activeTarget == null) {
      return _NoTargetPrompt(compact: compact, margin: margin);
    }

    final catalog = CosmeticsService.instance.getCatalog();
    final catalogItem = catalog
        .where((item) => item.id == activeTarget.targetCosmeticItemId)
        .firstOrNull;
    final displayName = catalogItem?.name ?? activeTarget.displayName;
    final rarity = catalogItem?.rarity ?? activeTarget.targetRarity;
    final color = CosmeticVisuals.rarityColor(rarity);
    final remaining = activeTarget.remainingFragments;
    final progressText =
        '${activeTarget.targetFragmentsOwned}/${activeTarget.targetFragmentsRequired}';
    final isSeasonItem = _maybeWatch<SeasonProvider>(context)
            ?.isSeasonFeaturedItem(activeTarget.targetCosmeticItemId) ??
        false;

    return Container(
      key: const Key('daily_run_target_header'),
      width: double.infinity,
      margin: margin,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppScale.radius(16)),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: AppScale.s(14),
          ),
        ],
      ),
      child: Row(
        children: [
          _TargetPreview(target: activeTarget, item: catalogItem, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$progressText fragments',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (remaining == 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    '1 more fragment!',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: activeTarget.progressValue,
                    minHeight: 7,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.18),
                  ),
                ),
                if (activeTarget.hasBonusProgress) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 11,
                        color: color.withValues(alpha: 0.80),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Bonus',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 5),
                      ...List.generate(CosmeticTarget.kBonusProgressMax, (i) {
                        final filled = i < activeTarget.bonusProgress;
                        return Container(
                          key: ValueKey('pip_$i'),
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? color.withValues(alpha: 0.90)
                                : color.withValues(alpha: 0.18),
                          ),
                        );
                      }),
                      const SizedBox(width: 3),
                      Text(
                        '${activeTarget.bonusProgress}/${CosmeticTarget.kBonusProgressMax}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color.withValues(alpha: 0.80),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ],  // end Column children
            ),  // end Column
          ),  // end Expanded
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSeasonItem)
                Container(
                  key: const Key('target_chase_season_badge'),
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Season',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.42)),
                ),
                child: Text(
                  rarity.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.10);
  }

  T? _maybeWatch<T>(BuildContext context) {
    try {
      return context.watch<T>();
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// No-target onboarding prompt
// ---------------------------------------------------------------------------

class _NoTargetPrompt extends StatelessWidget {
  const _NoTargetPrompt({required this.compact, required this.margin});

  final bool compact;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (compact) {
      // Compact: simple lock icon + "Pick your next chase" + button.
      return Container(
        key: const Key('no_target_prompt'),
        width: double.infinity,
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppScale.radius(14)),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primaryContainer.withValues(alpha: 0.55),
              ),
              child: Icon(
                Icons.gps_fixed_rounded,
                size: 18,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pick your next chase',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: () {
                try {
                  context.openAvatarCustomization();
                } catch (_) {}
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Choose'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 180.ms);
    }

    // Full (non-compact): title + subtitle + horizontal catalog tile strip.
    final suggestions = _pickSuggestions();

    return Container(
      key: const Key('no_target_prompt'),
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppScale.radius(14)),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick your next chase',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Tap any leaderboard cosmetic to start chasing it.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: suggestions
                    .map((item) => _SuggestionTile(item: item))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                try {
                  context.openAvatarCustomization();
                } catch (_) {}
              },
              icon: const Icon(Icons.apps_rounded, size: 16),
              label: const Text('Browse all cosmetics'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms);
  }

  /// Picks up to 3 items from the catalog, sorted by rarity (highest first),
  /// for the suggestion strip. Returns empty list if catalog unavailable.
  List<CosmeticItem> _pickSuggestions() {
    try {
      final catalog = CosmeticsService.instance.getCatalog();
      if (catalog.isEmpty) return [];
      final sorted = [...catalog]
        ..sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
      return sorted.take(3).toList();
    } catch (_) {
      return [];
    }
  }
}

// ---------------------------------------------------------------------------
// Suggestion tile shown in the no-target prompt strip
// ---------------------------------------------------------------------------

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.item});

  final CosmeticItem item;

  @override
  Widget build(BuildContext context) {
    final color = CosmeticVisuals.rarityColor(item.rarity);
    final loadout = _loadoutFor(item);

    return GestureDetector(
      onTap: () => showQuickChaseSheet(
        context: context,
        item: SocialCosmeticFlexItem(
          itemId: item.id,
          name: item.name,
          rarity: item.rarity,
          slotLabel: item.category.label,
          hasActualName: true,
        ),
      ),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget(
              size: 44,
              showFrame: true,
              overrideConfig: loadout.toAvatarConfig('suggestion-${item.id}'),
              borderColor: color,
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Chase',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SocialCosmeticLoadout _loadoutFor(CosmeticItem item) {
    if (item.category == CosmeticCategory.avatarFrame ||
        item.id.startsWith('frame_')) {
      return SocialCosmeticLoadout(avatarFrameId: item.id);
    }
    if (item.category == CosmeticCategory.profileBackground ||
        item.id.startsWith('bg_')) {
      return SocialCosmeticLoadout(profileBackgroundId: item.id);
    }
    if (item.category == CosmeticCategory.animatedEffect ||
        item.id.startsWith('effect_') ||
        item.id.startsWith('trail_')) {
      return SocialCosmeticLoadout(trailId: item.id);
    }
    return SocialCosmeticLoadout();
  }
}

// ---------------------------------------------------------------------------

class _TargetPreview extends StatelessWidget {
  const _TargetPreview({
    required this.target,
    required this.item,
    required this.color,
  });

  final CosmeticTarget target;
  final CosmeticItem? item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 12),
        ],
      ),
      child: AvatarWidget(
        size: 42,
        showFrame: true,
        overrideConfig: _targetLoadout().toAvatarConfig('target-preview'),
        borderColor: color,
      ),
    );
  }

  SocialCosmeticLoadout _targetLoadout() {
    final itemId = target.targetCosmeticItemId;
    final slot = target.targetSlotLabel?.toLowerCase();
    final category = item?.category;

    if (category == CosmeticCategory.avatarFrame ||
        itemId.startsWith('frame_') ||
        slot == 'frame') {
      return SocialCosmeticLoadout(avatarFrameId: itemId);
    }
    if (category == CosmeticCategory.profileBackground ||
        itemId.startsWith('bg_') ||
        slot == 'background') {
      return SocialCosmeticLoadout(profileBackgroundId: itemId);
    }
    if (category == CosmeticCategory.animatedEffect ||
        itemId.startsWith('effect_') ||
        slot == 'trail' ||
        slot == 'effect') {
      if (itemId.contains('trail') || slot == 'trail') {
        return SocialCosmeticLoadout(trailId: itemId);
      }
      return SocialCosmeticLoadout(answerEffectId: itemId);
    }
    return SocialCosmeticLoadout(avatarGearId: itemId);
  }
}
