import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player_identity.dart';
import '../state/player_identity_provider.dart';
import '../theme/tokens/spacing_tokens.dart';
import 'cosmetic_visuals.dart';
import 'player_title_chip.dart';

/// Opens the Trophy Room bottom sheet.
///
/// Shows earned / locked titles and the trophy collection.
void showTrophyRoomSheet(BuildContext context, {required String userId}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider<PlayerIdentityProvider>.value(
      value: context.read<PlayerIdentityProvider>(),
      child: _TrophyRoomSheet(userId: userId),
    ),
  );
}

class _TrophyRoomSheet extends StatefulWidget {
  const _TrophyRoomSheet({required this.userId});

  final String userId;

  @override
  State<_TrophyRoomSheet> createState() => _TrophyRoomSheetState();
}

class _TrophyRoomSheetState extends State<_TrophyRoomSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          key: const Key('trophy_room_sheet'),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Trophy Room',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Titles'),
                  Tab(text: 'Trophies'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _TitlesTab(scrollController: scrollController),
                    _TrophiesTab(scrollController: scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Titles tab ────────────────────────────────────────────────────────────────

class _TitlesTab extends StatelessWidget {
  const _TitlesTab({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final identity = context.watch<PlayerIdentityProvider>();
    final theme = Theme.of(context);

    return ListView.separated(
      key: const Key('trophy_titles_section'),
      controller: scrollController,
      padding: EdgeInsets.all(AppSpacing.base),
      itemCount: PlayerTitle.values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final title = PlayerTitle.values[index];
        final isEarned = identity.earnedTitles.contains(title);
        final isSelected = identity.featuredTitle == title;

        return _TitleRow(
          title: title,
          isEarned: isEarned,
          isSelected: isSelected,
          onTap: isEarned
              ? () {
                  identity.setSelectedTitle(isSelected ? null : title);
                }
              : null,
          theme: theme,
        );
      },
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.title,
    required this.isEarned,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  final PlayerTitle title;
  final bool isEarned;
  final bool isSelected;
  final VoidCallback? onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = isEarned
        ? PlayerTitleChip.colorFor(title)
        : theme.colorScheme.onSurface.withValues(alpha: 0.25);
    final borderColor =
        isSelected ? color : color.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? color.withValues(alpha: 0.10)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
        ),
        child: Row(
          children: [
            Icon(
              PlayerTitleChip.iconFor(title),
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isEarned
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title.unlockCriteria,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isEarned && isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 18)
            else if (isEarned)
              Icon(
                Icons.radio_button_unchecked,
                color: color.withValues(alpha: 0.6),
                size: 18,
              )
            else
              Icon(
                Icons.lock_outline_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Trophies tab ──────────────────────────────────────────────────────────────

class _TrophiesTab extends StatelessWidget {
  const _TrophiesTab({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final trophies = context
        .select<PlayerIdentityProvider, List<TrophyEntry>>(
          (p) => p.trophies,
        );
    final theme = Theme.of(context);

    if (trophies.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 12),
              Text(
                'No trophies yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Complete daily runs and unlock rare cosmetics to earn trophies.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group by category
    final byCategory = <TrophyCategory, List<TrophyEntry>>{};
    for (final entry in trophies) {
      byCategory.putIfAbsent(entry.category, () => []).add(entry);
    }
    final categories = byCategory.keys.toList();

    return ListView.builder(
      key: const Key('trophy_items_section'),
      controller: scrollController,
      padding: EdgeInsets.all(AppSpacing.base),
      itemCount: categories.fold<int>(
        0,
        (sum, cat) => sum + 1 + (byCategory[cat]?.length ?? 0),
      ),
      itemBuilder: (context, index) {
        // Map flat index to category/item
        var remaining = index;
        for (final cat in categories) {
          final items = byCategory[cat]!;
          if (remaining == 0) {
            return _SectionHeader(category: cat, theme: theme);
          }
          remaining--;
          if (remaining < items.length) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TrophyRow(entry: items[remaining], theme: theme),
            );
          }
          remaining -= items.length;
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.category, required this.theme});

  final TrophyCategory category;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Icon(
            _categoryIcon(category),
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            category.sectionLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(TrophyCategory cat) {
    switch (cat) {
      case TrophyCategory.season:
        return Icons.workspace_premium_rounded;
      case TrophyCategory.legendary:
        return Icons.emoji_events_rounded;
      case TrophyCategory.rare:
        return Icons.diamond_rounded;
      case TrophyCategory.milestone:
        return Icons.flag_rounded;
    }
  }
}

class _TrophyRow extends StatelessWidget {
  const _TrophyRow({required this.entry, required this.theme});

  final TrophyEntry entry;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final rarity = entry.rarity;
    final accentColor = rarity != null
        ? CosmeticVisuals.rarityColor(rarity)
        : theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
        color: accentColor.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
            ),
            child: Icon(
              _iconForCategory(entry.category),
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (entry.sublabel != null)
                  Text(
                    entry.sublabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          if (rarity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accentColor.withValues(alpha: 0.15),
              ),
              child: Text(
                rarity.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _iconForCategory(TrophyCategory cat) {
    switch (cat) {
      case TrophyCategory.season:
        return Icons.workspace_premium_rounded;
      case TrophyCategory.legendary:
        return Icons.emoji_events_rounded;
      case TrophyCategory.rare:
        return Icons.diamond_rounded;
      case TrophyCategory.milestone:
        return Icons.flag_rounded;
    }
  }
}
