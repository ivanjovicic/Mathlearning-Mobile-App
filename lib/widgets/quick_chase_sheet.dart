import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cosmetic_item.dart';
import '../models/cosmetic_target.dart';
import '../models/social_cosmetic_loadout.dart';
import '../services/cosmetic_target_service.dart';
import '../services/cosmetics_service.dart';
import '../services/sound_service.dart';
import '../state/cosmetic_target_provider.dart';
import 'avatar_widget.dart';
import 'cosmetic_try_on_panel.dart';
import 'cosmetic_visuals.dart';

/// Opens a compact "Chase this?" bottom sheet for any cosmetic item — designed
/// to be triggered from the leaderboard without requiring navigation.
///
/// One tap on the chip → sheet opens.
/// One tap on "Set as target" → target locked and sheet closes.
Future<void> showQuickChaseSheet({
  required BuildContext context,
  required SocialCosmeticFlexItem item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _QuickChaseSheet(
      item: item,
      navigationContext: context,
    ),
  );
}

class _QuickChaseSheet extends StatefulWidget {
  const _QuickChaseSheet({
    required this.item,
    required this.navigationContext,
  });

  final SocialCosmeticFlexItem item;
  final BuildContext navigationContext;

  @override
  State<_QuickChaseSheet> createState() => _QuickChaseSheetState();
}

class _QuickChaseSheetState extends State<_QuickChaseSheet> {
  bool _saving = false;
  bool _justSet = false;
  bool _previewing = false;

  CosmeticTargetProvider? get _provider {
    try {
      return context.read<CosmeticTargetProvider>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _setTarget() async {
    setState(() => _saving = true);
    final provider = _provider;
    if (provider != null) {
      await provider.setTargetFromFlexItem(item: widget.item);
    } else {
      await _saveWithoutProvider();
    }
    await SoundService.instance.haptic(SoundHaptic.mediumImpact);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _justSet = true;
    });
    // Brief delay so the user sees confirmation before the sheet auto-closes.
    await Future<void>.delayed(const Duration(milliseconds: 620));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _saveWithoutProvider() async {
    final required = CosmeticsService.dailyRunRequiredFragments;
    final target = CosmeticTarget(
      targetCosmeticItemId: widget.item.itemId,
      targetFragmentsOwned: 0,
      targetFragmentsRequired: required,
      targetRarity: widget.item.rarity,
      targetItemName: widget.item.name,
      targetSlotLabel: widget.item.slotLabel,
      updatedAt: DateTime.now(),
    );
    await CosmeticTargetService.instance.saveTarget(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final color = CosmeticVisuals.rarityColor(widget.item.rarity);
    final isCurrentTarget = _maybeWatchCurrentTarget(context) ==
        widget.item.itemId;
    final isCurrent = isCurrentTarget || _justSet;
    final loadout = _loadoutForItem(widget.item);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _previewing
              ? CosmeticTryOnPanel(
                  key: const ValueKey('quick-chase-preview-panel'),
                  item: widget.item,
                  isCurrentTarget: isCurrent,
                  onChaseThis: _setTarget,
                  onBackToLook: () => setState(() => _previewing = false),
                )
              : Column(
                  key: const ValueKey('quick-chase-content'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: color.withValues(alpha: 0.50),
                              width: 1.5,
                            ),
                          ),
                          child: AvatarWidget(
                            size: 54,
                            showFrame: true,
                            overrideConfig: loadout.toAvatarConfig(
                              'quick-chase-preview',
                            ),
                            borderColor: color,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chase ${widget.item.name}?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _RarityPill(rarity: widget.item.rarity),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // ── Race flavor (local, no fake counts) ───────────────────
                    _FlavorLabel(rarity: widget.item.rarity),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'See it on your avatar',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const Key('quick_chase_try_on_button'),
                              onPressed: () => setState(() => _previewing = true),
                              icon: const Icon(Icons.visibility_rounded),
                              label: const Text('Try the look'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Primary CTA ───────────────────────────────────────────
                    AnimatedScale(
                      scale: _justSet ? 1.02 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('quick_chase_set_target_button'),
                          onPressed: isCurrent || _saving ? null : _setTarget,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: isCurrent
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    key: ValueKey('done'),
                                  )
                                : _saving
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.gps_fixed_rounded,
                                    key: ValueKey('chase'),
                                  ),
                          ),
                          label: Text(
                            isCurrent
                                ? _justSet
                                    ? 'Chase started!'
                                    : 'Already chasing'
                                : 'Set as target',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: isCurrent
                                ? colors.primaryContainer
                                : color,
                            foregroundColor: isCurrent
                                ? colors.onPrimaryContainer
                                : colors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String? _maybeWatchCurrentTarget(BuildContext context) {
    try {
      return context.watch<CosmeticTargetProvider>().target?.targetCosmeticItemId;
    } catch (_) {
      return null;
    }
  }

  SocialCosmeticLoadout _loadoutForItem(SocialCosmeticFlexItem item) {
    final slot = item.slotLabel.toLowerCase();
    final id = item.itemId;
    if (id.startsWith('frame_') || slot == 'frame') {
      return SocialCosmeticLoadout(avatarFrameId: id);
    }
    if (id.startsWith('bg_') || slot == 'background') {
      return SocialCosmeticLoadout(profileBackgroundId: id);
    }
    if (id.startsWith('trail_') || slot == 'trail') {
      return SocialCosmeticLoadout(trailId: id);
    }
    if (id.startsWith('effect_') || slot == 'effect') {
      return SocialCosmeticLoadout(answerEffectId: id);
    }
    return SocialCosmeticLoadout();
  }
}

class _RarityPill extends StatelessWidget {
  const _RarityPill({required this.rarity});

  final CosmeticRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = CosmeticVisuals.rarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Text(
        rarity.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Label showing lightweight popularity flavor — never fake numeric counts.
class _FlavorLabel extends StatelessWidget {
  const _FlavorLabel({required this.rarity});

  final CosmeticRarity rarity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, text) = switch (rarity) {
      CosmeticRarity.common || CosmeticRarity.rare => (
          Icons.trending_up_rounded,
          'Popular this week',
        ),
      CosmeticRarity.epic || CosmeticRarity.mythic => (
          Icons.local_fire_department_rounded,
          'Many players are chasing this',
        ),
      CosmeticRarity.legendary => (
          Icons.auto_awesome_rounded,
          'One of the rarest items available',
        ),
    };
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
