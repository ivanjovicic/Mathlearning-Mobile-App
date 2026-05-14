import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/season.dart';
import 'package:mathlearning/state/season_provider.dart';
import 'package:mathlearning/widgets/cosmetic_visuals.dart';

/// Opens the season hub as a modal bottom sheet.
void showSeasonHub(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<SeasonProvider>(),
      child: const SeasonHubSheet(),
    ),
  );
}

class SeasonHubSheet extends StatelessWidget {
  const SeasonHubSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final season = context.watch<SeasonProvider>();

    if (season.isLoading) {
      return _SheetShell(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final s = season.season;
    if (s == null) {
      return _SheetShell(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No active season right now.\nCheck back soon!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return _SheetShell(child: _SeasonContent(season: season, s: s));
  }
}

// ── Shell ──────────────────────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ColoredBox(color: colors.surface, child: child),
      ),
    );
  }
}

// ── Main content ───────────────────────────────────────────────────────────

class _SeasonContent extends StatelessWidget {
  const _SeasonContent({required this.season, required this.s});

  final SeasonProvider season;
  final Season s;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = s.status(now);
    final xp = season.earnedXp;
    final goal = season.totalXpGoal;
    final fraction = season.progressFraction;
    final percent = season.completionPercent;
    final featured = season.featuredCosmeticItem;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accentColor = _themeColor(s.theme, colors);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SeasonHeader(
            season: s,
            status: status,
            accentColor: accentColor,
            now: now,
          ),
        ),
        if (status != SeasonStatus.active && status != SeasonStatus.ended)
          SliverToBoxAdapter(
            child: _UrgencyBanner(status: status, season: s, now: now),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _XpProgressCard(
              xp: xp,
              goal: goal,
              fraction: fraction,
              percent: percent,
              accentColor: accentColor,
            ),
          ),
        ),
        if (featured != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _FeaturedCosmeticCard(
                item: featured,
                accentColor: accentColor,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
            child: Text(
              'Season rewards',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: s.milestones.length,
          itemBuilder: (context, i) {
            final milestone = s.milestones[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _MilestoneRow(
                milestone: milestone,
                earnedXp: xp,
                accentColor: accentColor,
                canClaim: season.canClaimMilestone(milestone),
                isClaimed: season.isMilestoneClaimed(milestone.id),
                onClaim: () => _onClaimTap(context, season, milestone),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Color _themeColor(String theme, ColorScheme colors) {
    switch (theme) {
      case 'olympiad':
        return const Color(0xFFFFD700);
      case 'galaxy':
        return const Color(0xFF7B5EFF);
      case 'arctic':
        return const Color(0xFF29B6F6);
      case 'winter':
        return const Color(0xFF80CBC4);
      default:
        return colors.primary;
    }
  }

  Future<void> _onClaimTap(
    BuildContext context,
    SeasonProvider provider,
    SeasonMilestone milestone,
  ) async {
    final result = await provider.claimMilestone(milestone);
    if (!context.mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.milestone.rewardLabel ?? "Reward"} unlocked!',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorReason ?? 'Could not claim reward'),
        ),
      );
    }
  }
}

// ── Season header ──────────────────────────────────────────────────────────

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader({
    required this.season,
    required this.status,
    required this.accentColor,
    required this.now,
  });

  final Season season;
  final SeasonStatus status;
  final Color accentColor;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const Key('season_header'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.22),
            accentColor.withValues(alpha: 0.05),
            colors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'SEASON',
                  style: textTheme.labelSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (status != SeasonStatus.ended)
                Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      size: 14,
                      color: status.isUrgent
                          ? colors.error
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      season.countdownLabel(now),
                      key: const Key('season_countdown_label'),
                      style: textTheme.labelMedium?.copyWith(
                        color: status.isUrgent
                            ? colors.error
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            season.name,
            key: const Key('season_name_label'),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Urgency banner ─────────────────────────────────────────────────────────

class _UrgencyBanner extends StatelessWidget {
  const _UrgencyBanner({
    required this.status,
    required this.season,
    required this.now,
  });

  final SeasonStatus status;
  final Season season;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final copy = status.urgencyLabel;
    if (copy.isEmpty) return const SizedBox.shrink();

    final isLastDay = status == SeasonStatus.endingSoon24h;
    final bgColor =
        isLastDay ? colors.errorContainer : colors.tertiaryContainer;
    final fgColor =
        isLastDay ? colors.onErrorContainer : colors.onTertiaryContainer;

    return Container(
      key: const Key('season_urgency_banner'),
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isLastDay ? Icons.warning_amber_rounded : Icons.schedule_rounded,
            color: fgColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              copy,
              key: const Key('season_urgency_copy'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: -0.2, end: 0);
  }
}

// ── XP progress card ───────────────────────────────────────────────────────

class _XpProgressCard extends StatelessWidget {
  const _XpProgressCard({
    required this.xp,
    required this.goal,
    required this.fraction,
    required this.percent,
    required this.accentColor,
  });

  final int xp;
  final int goal;
  final double fraction;
  final int percent;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Season XP',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '$xp / $goal XP',
                key: const Key('season_xp_label'),
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              key: const Key('season_progress_bar'),
              value: fraction,
              minHeight: 12,
              backgroundColor: colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percent% complete',
            key: const Key('season_completion_percent'),
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Featured cosmetic ──────────────────────────────────────────────────────

class _FeaturedCosmeticCard extends StatelessWidget {
  const _FeaturedCosmeticCard({
    required this.item,
    required this.accentColor,
  });

  final CosmeticItem item;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rarityColor = CosmeticVisuals.rarityColor(item.rarity);

    return Container(
      key: const Key('season_featured_cosmetic_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rarityColor.withValues(alpha: 0.18),
            rarityColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarityColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rarityColor.withValues(alpha: 0.18),
              border: Border.all(color: rarityColor.withValues(alpha: 0.6)),
            ),
            child: Center(
              child: Text(
                item.assetKey.length <= 2 ? item.assetKey : '🏆',
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${item.rarity.label.toUpperCase()} · Season reward',
                    style: textTheme.labelSmall?.copyWith(
                      color: rarityColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Max out season XP to earn this',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Milestone row ──────────────────────────────────────────────────────────

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.milestone,
    required this.earnedXp,
    required this.accentColor,
    required this.canClaim,
    required this.isClaimed,
    required this.onClaim,
  });

  final SeasonMilestone milestone;
  final int earnedXp;
  final Color accentColor;
  final bool canClaim;
  final bool isClaimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final reached = earnedXp >= milestone.xpRequired;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rarityColor = CosmeticVisuals.rarityColor(milestone.rarity);

    return AnimatedContainer(
      key: Key('milestone_row_${milestone.id}'),
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isClaimed
            ? colors.surfaceContainerLow
            : reached
            ? rarityColor.withValues(alpha: 0.10)
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isClaimed
              ? colors.outlineVariant.withValues(alpha: 0.4)
              : reached
              ? rarityColor.withValues(alpha: 0.50)
              : colors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isClaimed
                  ? colors.primaryContainer
                  : reached
                  ? rarityColor.withValues(alpha: 0.20)
                  : colors.surfaceContainerHighest,
            ),
            child: Center(
              child: Icon(
                isClaimed
                    ? Icons.check_rounded
                    : reached
                    ? Icons.lock_open_rounded
                    : Icons.lock_rounded,
                size: 18,
                color: isClaimed
                    ? colors.primary
                    : reached
                    ? rarityColor
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.rewardLabel ?? milestone.label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isClaimed
                        ? colors.onSurfaceVariant
                        : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${milestone.xpRequired} XP · ${milestone.rewardType.label}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isClaimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Claimed',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (canClaim)
            FilledButton(
              key: Key('claim_milestone_${milestone.id}'),
              onPressed: onClaim,
              style: FilledButton.styleFrom(
                backgroundColor: rarityColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Claim!'),
            )
          else
            Text(
              '${(milestone.xpRequired - earnedXp).clamp(0, 9999)} XP away',
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
