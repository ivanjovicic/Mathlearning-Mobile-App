import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/player_identity_provider.dart';
import '../theme/tokens/spacing_tokens.dart';
import 'cosmetic_visuals.dart';
import 'player_title_chip.dart';
import 'trophy_room_sheet.dart';

/// Compact showcase card that surfaces a player's identity:
/// featured title, rarest owned cosmetic, streak, and daily run count.
///
/// Self-hides (returns [SizedBox.shrink]) when the provider is loading and
/// no data has arrived yet (e.g. first cold start).
class IdentityShowcaseSection extends StatelessWidget {
  const IdentityShowcaseSection({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final identity = context.watch<PlayerIdentityProvider>();

    if (identity.isLoading && !identity.hasAnyTitle) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final featuredTitle = identity.featuredTitle;
    final borderColor = identity.rarestOwnedRarity != null
        ? CosmeticVisuals.rarityColor(
            identity.rarestOwnedRarity!,
          ).withValues(alpha: 0.5)
        : colorScheme.outline.withValues(alpha: 0.3);

    return Container(
      key: const Key('identity_showcase_section'),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      padding: EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: title chip + trophy room button
          Row(
            children: [
              if (featuredTitle != null) ...[
                PlayerTitleChip(title: featuredTitle),
                const SizedBox(width: 8),
              ] else ...[
                Text(
                  'No title yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              GestureDetector(
                onTap: () => showTrophyRoomSheet(context, userId: userId),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Trophy Room',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          // Stat row
          Row(
            children: [
              if (identity.rarestOwnedItemName != null) ...[
                _StatChip(
                  key: const Key('identity_rarest_cosmetic'),
                  icon: Icons.diamond_outlined,
                  label: identity.rarestOwnedItemName!,
                  color: identity.rarestOwnedRarity != null
                      ? CosmeticVisuals.rarityColor(identity.rarestOwnedRarity!)
                      : colorScheme.secondary,
                ),
                const SizedBox(width: 8),
              ],
              if (identity.currentStreak > 0) ...[
                _StatChip(
                  key: const Key('identity_streak'),
                  icon: Icons.local_fire_department_rounded,
                  label: '${identity.currentStreak}d streak',
                  color: const Color(0xFFFF7043),
                ),
                const SizedBox(width: 8),
              ],
              if (identity.totalAttempts > 0)
                _StatChip(
                  icon: Icons.directions_run_rounded,
                  label: '${identity.totalAttempts} runs',
                  color: colorScheme.primary,
                ),
            ],
          ),
          // "Set title" prompt when no title selected yet
          if (identity.hasAnyTitle && identity.featuredTitle == null) ...[
            SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () => showTrophyRoomSheet(context, userId: userId),
              child: Text(
                'Tap to set your profile title →',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
