import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cosmetic_item.dart';
import '../models/user_avatar.dart';
import '../state/avatar_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/cosmetic_item_card.dart';
import '../widgets/cosmetic_visuals.dart';

/// Full-screen avatar customisation UI.
///
/// Left/top: live avatar preview.
/// Bottom: category tab bar + item grid.
class AvatarCustomizationScreen extends StatefulWidget {
  const AvatarCustomizationScreen({super.key});

  @override
  State<AvatarCustomizationScreen> createState() =>
      _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState
    extends State<AvatarCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Live preview override — updated as the user taps items.
  UserAvatar? _previewConfig;

  static const _categories = [
    CosmeticCategory.avatarSkin,
    CosmeticCategory.hairStyle,
    CosmeticCategory.clothing,
    CosmeticCategory.accessory,
    CosmeticCategory.emojiReaction,
    CosmeticCategory.avatarFrame,
    CosmeticCategory.profileBackground,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Equip / preview ─────────────────────────────────────────────────────

  void _previewItem(CosmeticItem item, AvatarProvider provider) {
    setState(() {
      final base = _previewConfig ?? provider.avatarConfig;
      if (base == null) return;
      _previewConfig = _applyPreview(base, item);
    });
  }

  UserAvatar _applyPreview(UserAvatar base, CosmeticItem item) {
    switch (item.category) {
      case CosmeticCategory.avatarSkin:
        return base.copyWith(skinId: item.id);
      case CosmeticCategory.hairStyle:
        return base.copyWith(hairId: item.id);
      case CosmeticCategory.clothing:
        return base.copyWith(clothingId: item.id);
      case CosmeticCategory.accessory:
        return base.copyWith(accessoryId: item.id);
      case CosmeticCategory.emojiReaction:
        return base.copyWith(emojiId: item.id);
      case CosmeticCategory.avatarFrame:
        return base.copyWith(frameId: item.id);
      case CosmeticCategory.profileBackground:
        return base.copyWith(backgroundId: item.id);
      default:
        return base;
    }
  }

  Future<void> _saveAvatar(AvatarProvider provider) async {
    if (_previewConfig == null) return;
    await provider.updateAvatarConfig(_previewConfig!);
    _previewConfig = null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Avatar sačuvan!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _discardChanges(AvatarProvider provider) {
    setState(() => _previewConfig = null);
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AvatarProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasChanges = _previewConfig != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Prilagodi avatar'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          if (hasChanges)
            TextButton.icon(
              onPressed: () => _discardChanges(provider),
              icon: const Icon(Icons.undo),
              label: const Text('Ponisti'),
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Avatar Preview ──────────────────────────────
                _AvatarPreviewSection(
                  previewConfig: _previewConfig,
                  provider: provider,
                ),

                const Divider(height: 1),

                // ── Category Tab Bar ────────────────────────────
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor:
                      colorScheme.onSurface.withOpacity(0.5),
                  indicatorColor: colorScheme.primary,
                  tabs: _categories
                      .map(
                        (cat) => Tab(
                          icon: Icon(_categoryIcon(cat), size: 18),
                          text: cat.label,
                        ),
                      )
                      .toList(),
                ),

                // ── Item Grid ───────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _categories.map((cat) {
                      return _CategoryGrid(
                        category: cat,
                        provider: provider,
                        previewConfig: _previewConfig,
                        onItemTap: (item) => _previewItem(item, provider),
                      );
                    }).toList(),
                  ),
                ),

                // ── Save Button ─────────────────────────────────
                _SaveBar(
                  hasChanges: hasChanges,
                  onSave: () => _saveAvatar(provider),
                ),
              ],
            ),
    );
  }

  IconData _categoryIcon(CosmeticCategory cat) {
    switch (cat) {
      case CosmeticCategory.avatarSkin:
        return Icons.face;
      case CosmeticCategory.hairStyle:
        return Icons.auto_awesome;
      case CosmeticCategory.clothing:
        return Icons.checkroom;
      case CosmeticCategory.accessory:
        return Icons.diamond_outlined;
      case CosmeticCategory.emojiReaction:
        return Icons.emoji_emotions_outlined;
      case CosmeticCategory.avatarFrame:
        return Icons.crop_square;
      case CosmeticCategory.profileBackground:
        return Icons.wallpaper;
      default:
        return Icons.star;
    }
  }
}

// ─── Avatar Preview Section ──────────────────────────────────────────────────

class _AvatarPreviewSection extends StatelessWidget {
  const _AvatarPreviewSection({
    required this.previewConfig,
    required this.provider,
  });

  final UserAvatar? previewConfig;
  final AvatarProvider provider;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final config = previewConfig ?? provider.avatarConfig;
    final bgDeco = CosmeticVisuals.backgroundDecoration(
      config?.backgroundId,
      BorderRadius.circular(0),
    );

    return Container(
      height: 180,
      decoration: bgDeco,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarWidget(
              size: 110,
              showFrame: true,
              overrideConfig: config,
              borderColor: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            // Equipped emoji indicator
            if (config?.emojiId != null)
              () {
                final item = provider.catalog
                    .where((c) => c.id == config!.emojiId)
                    .firstOrNull;
                if (item == null) return const SizedBox.shrink();
                return Text(
                  item.assetKey,
                  style: const TextStyle(fontSize: 20),
                );
              }(),
          ],
        ),
      ),
    );
  }
}

// ─── Category Grid ───────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.category,
    required this.provider,
    required this.previewConfig,
    required this.onItemTap,
  });

  final CosmeticCategory category;
  final AvatarProvider provider;
  final UserAvatar? previewConfig;
  final void Function(CosmeticItem) onItemTap;

  @override
  Widget build(BuildContext context) {
    final entries = provider.catalogForCategory(category);
    final previewEquipped =
        previewConfig?.slotFor(category.id) ??
        provider.equippedIdFor(category);

    final ownedCount = entries.where((e) => e.owned).length;

    return Column(
      children: [
        // Completion progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Text(
                'Posjedujete: $ownedCount/${entries.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${(ownedCount / entries.length * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: entries.isEmpty ? 0 : ownedCount / entries.length,
          minHeight: 3,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isEquipped = entry.item.id == previewEquipped;

              return CosmeticItemCard(
                item: entry.item,
                isOwned: entry.owned,
                isEquipped: isEquipped,
                onTap: () => onItemTap(entry.item),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Save Bar ────────────────────────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.hasChanges, required this.onSave});

  final bool hasChanges;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).padding.bottom;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: hasChanges ? (56 + bottom) : 0,
      child: hasChanges
          ? Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 8),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_alt_rounded),
                  label: const Text('Sačuvaj avatar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
