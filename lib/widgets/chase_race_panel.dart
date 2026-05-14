import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/chase_race.dart';
import '../state/chase_race_provider.dart';
import 'cosmetic_visuals.dart';
import 'social_cosmetic_avatar.dart';

// ── Entry point for the full leaderboard sheet ───────────────────────────────

/// Opens a full-screen draggable sheet showing all race participants.
///
/// No-ops silently when there is no active race with competitors.
void showChaseRaceSheet(BuildContext context) {
  ChaseRaceProvider provider;
  try {
    provider = context.read<ChaseRaceProvider>();
  } catch (_) {
    return;
  }
  final race = provider.race;
  if (race == null || !race.hasCompetitors) return;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const _ChaseRaceSheet(),
    ),
  );
}

// ── Compact inline panel (embedded in TargetCosmeticChaseCard) ───────────────

/// Compact panel that appears below the chase progress card when there is an
/// active race with at least one other participant.
///
/// Handles its own visibility — callers may always include it in the tree.
class ChaseRacePanel extends StatelessWidget {
  const ChaseRacePanel({super.key});

  @override
  Widget build(BuildContext context) {
    ChaseRaceProvider provider;
    try {
      provider = context.watch<ChaseRaceProvider>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    if (provider.isLoading) {
      return const _PanelLoadingPlaceholder();
    }

    final race = provider.race;
    if (race == null || !race.hasCompetitors) return const SizedBox.shrink();

    final color = CosmeticVisuals.rarityColor(race.itemRarity);
    final messages = provider.catchUpMessages;
    final myUserId = provider.myEntry?.userId;
    final shown = race.participants.take(4).toList();
    final overflow = race.participants.length - shown.length;

    return Container(
      key: const Key('chase_race_panel'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 13,
                color: color,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Race for ${race.itemName}',
                  key: const Key('chase_race_panel_headline'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              TextButton(
                key: const Key('chase_race_view_all_button'),
                onPressed: () => showChaseRaceSheet(context),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: color,
                ),
                child: Text(
                  overflow > 0 ? 'View all' : 'View race',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),

          // ── Catch-up message ─────────────────────────────────────────────
          if (messages.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              messages.first,
              key: const Key('chase_race_catchup_message'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          // ── Participant rows ─────────────────────────────────────────────
          const SizedBox(height: 8),
          for (final entry in shown)
            _CompactParticipantRow(
              key: Key('race_compact_row_${entry.userId}'),
              entry: entry,
              color: color,
              isMe: entry.userId == myUserId,
            ),

          // ── Overflow hint ────────────────────────────────────────────────
          if (overflow > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => showChaseRaceSheet(context),
                child: Text(
                  '+$overflow more in race',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08);
  }
}

// ── Row in compact panel ─────────────────────────────────────────────────────

class _CompactParticipantRow extends StatelessWidget {
  const _CompactParticipantRow({
    super.key,
    required this.entry,
    required this.color,
    required this.isMe,
  });

  final ChaseRaceEntry entry;
  final Color color;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final isFirstFinisher = entry.rank == 1 && entry.isComplete;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isMe
                  ? color.withValues(alpha: 0.22)
                  : colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: isFirstFinisher
                ? Icon(Icons.emoji_events_rounded, size: 10, color: color)
                : Text(
                    '${entry.rank}',
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isMe ? color : colors.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 5),
          // Avatar
          SocialCosmeticAvatar(
            userId: entry.userId,
            displayName: entry.displayName,
            avatarUrl: entry.avatarUrl,
            loadout: entry.cosmeticLoadout,
            size: 22,
            showRecentBadge: false,
          ),
          const SizedBox(width: 6),
          // Name
          Expanded(
            child: Text(
              isMe ? 'You' : entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: isMe ? FontWeight.w900 : FontWeight.w600,
                color: isMe ? color : colors.onSurface,
              ),
            ),
          ),
          // Fragments text
          Text(
            '${entry.fragmentsOwned}/${entry.fragmentsRequired}',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: entry.isComplete ? color : colors.onSurfaceVariant,
            ),
          ),
          // Today's gain badge
          if (entry.todayGained > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+${entry.todayGained}',
                key: Key('race_today_gained_${entry.userId}'),
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Loading placeholder ──────────────────────────────────────────────────────

class _PanelLoadingPlaceholder extends StatelessWidget {
  const _PanelLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('chase_race_panel_loading'),
      margin: const EdgeInsets.only(top: 10),
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

// ── Full leaderboard sheet ───────────────────────────────────────────────────

class _ChaseRaceSheet extends StatelessWidget {
  const _ChaseRaceSheet();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChaseRaceProvider>();
    final race = provider.race;
    if (race == null) return const SizedBox.shrink();

    final color = CosmeticVisuals.rarityColor(race.itemRarity);
    final messages = provider.catchUpMessages;
    final myUserId = provider.myEntry?.userId;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // ── Sheet header ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events_rounded,
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Race for ${race.itemName}',
                            key: const Key('chase_race_sheet_title'),
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ),
                        Text(
                          '${race.participants.length} racers',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // ── Catch-up banner ──────────────────────────────────
                    if (messages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: color.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final msg in messages)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  msg,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              // ── Participant list ───────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: race.participants.length,
                  itemBuilder: (context, index) {
                    final entry = race.participants[index];
                    return _FullParticipantRow(
                      key: Key('race_full_row_${entry.userId}'),
                      entry: entry,
                      color: color,
                      isMe: entry.userId == myUserId,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Row in full sheet ────────────────────────────────────────────────────────

class _FullParticipantRow extends StatelessWidget {
  const _FullParticipantRow({
    super.key,
    required this.entry,
    required this.color,
    required this.isMe,
  });

  final ChaseRaceEntry entry;
  final Color color;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final isFirstFinisher = entry.rank == 1 && entry.isComplete;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe
            ? color.withValues(alpha: 0.08)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: isMe
            ? Border.all(color: color.withValues(alpha: 0.30))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: isFirstFinisher
                ? Icon(
                    Icons.emoji_events_rounded,
                    color: color,
                    size: 20,
                  )
                : Text(
                    '#${entry.rank}',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isMe ? color : colors.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // Avatar
          SocialCosmeticAvatar(
            userId: entry.userId,
            displayName: entry.displayName,
            avatarUrl: entry.avatarUrl,
            loadout: entry.cosmeticLoadout,
            size: 38,
            showRecentBadge: false,
          ),
          const SizedBox(width: 10),
          // Name + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isMe ? 'You' : entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.w600,
                          color: isMe ? color : colors.onSurface,
                        ),
                      ),
                    ),
                    if (isFirstFinisher) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'First to Unlock',
                          key: Key('first_to_unlock_${entry.userId}'),
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: entry.progressValue,
                          minHeight: 5,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.fragmentsOwned}/${entry.fragmentsRequired}',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: entry.isComplete ? color : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Today's gain
          if (entry.todayGained > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+${entry.todayGained} today',
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
