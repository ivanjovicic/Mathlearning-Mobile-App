import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cosmetic_fragment_progress.dart';
import '../models/cosmetic_item.dart';
import '../models/cosmetic_target.dart';
import '../models/social_cosmetic_loadout.dart';
import '../navigation/app_routes.dart';
import '../services/cosmetic_target_service.dart';
import '../services/cosmetics_service.dart';
import '../services/sound_service.dart';
import '../state/cosmetic_target_provider.dart';
import 'avatar_widget.dart';
import 'cosmetic_try_on_panel.dart';
import 'cosmetic_visuals.dart';

Future<void> showCosmeticDetailSheet({
  required BuildContext context,
  required SocialCosmeticLoadout loadout,
  required SocialCosmeticFlexItem item,
  required bool isCurrentUser,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => CosmeticDetailSheet(
      loadout: loadout,
      item: item,
      isCurrentUser: isCurrentUser,
      navigationContext: context,
    ),
  );
}

class CosmeticDetailSheet extends StatefulWidget {
  const CosmeticDetailSheet({
    super.key,
    required this.loadout,
    required this.item,
    required this.isCurrentUser,
    required this.navigationContext,
    this.progressLoader,
  });

  final SocialCosmeticLoadout loadout;
  final SocialCosmeticFlexItem item;
  final bool isCurrentUser;
  final BuildContext navigationContext;
  final Future<CosmeticFragmentProgress?> Function(String itemId)?
  progressLoader;

  @override
  State<CosmeticDetailSheet> createState() => _CosmeticDetailSheetState();
}

class _CosmeticDetailSheetState extends State<CosmeticDetailSheet> {
  bool _previewing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final targetProvider = _maybeWatch<CosmeticTargetProvider>(context);
    final isCurrentTarget =
        targetProvider?.target?.targetCosmeticItemId == widget.item.itemId;
    final rarityColor = CosmeticVisuals.rarityColor(widget.item.rarity);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: FutureBuilder<CosmeticFragmentProgress?>(
          future: _loadProgress(widget.item.itemId),
          builder: (context, snapshot) {
            final progress = snapshot.data;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _previewing
                  ? CosmeticTryOnPanel(
                      key: const ValueKey('detail-preview-panel'),
                      item: widget.item,
                      isCurrentTarget: isCurrentTarget,
                      onChaseThis: () => _setTargetFromPreview(
                        progress: progress,
                        targetProvider: targetProvider,
                      ),
                      onBackToLook: () => setState(() => _previewing = false),
                    )
                  : Column(
                      key: const ValueKey('detail-sheet-content'),
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CosmeticPreview(
                              loadout: widget.loadout,
                              color: rarityColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item.name,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _RarityPill(rarity: widget.item.rarity),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'How to get it',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Earn fragments from Daily Run chests.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Daily chests can drop this fragment.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: rarityColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: rarityColor.withValues(alpha: 0.30),
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
                                  key: const Key('detail_try_on_button'),
                                  onPressed: () =>
                                      setState(() => _previewing = true),
                                  icon: const Icon(Icons.visibility_rounded),
                                  label: const Text('Try the look'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (widget.isCurrentUser) ...[
                          _FragmentProgress(progress: progress),
                          const SizedBox(height: 18),
                        ],
                        _SetTargetButton(
                          item: widget.item,
                          progress: progress,
                          targetProvider: targetProvider,
                          isCurrentTarget: isCurrentTarget,
                          onSetWithoutProvider: () =>
                              _saveTargetWithoutProvider(progress: progress),
                        ),
                        const SizedBox(height: 10),
                        _DailyRunCta(
                          label: widget.isCurrentUser
                              ? _ctaLabel(progress)
                              : 'Start Daily Run',
                          navigationContext: widget.navigationContext,
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Future<CosmeticFragmentProgress?> _loadProgress(String itemId) async {
    final loader = widget.progressLoader;
    if (loader != null) {
      return loader(itemId);
    }
    final progress = await CosmeticsService.instance.loadFragmentProgress();
    return progress.where((entry) => entry.itemId == itemId).firstOrNull;
  }

  String _ctaLabel(CosmeticFragmentProgress? progress) {
    if (progress == null || progress.isUnlocked) return 'Start Daily Run';
    final remaining = progress.requiredFragments - progress.collectedFragments;
    if (remaining <= 0) return 'Start Daily Run';
    if (remaining == 1) return 'Start Daily Run — 1 more!';
    return 'Start Daily Run — $remaining more to unlock';
  }

  Future<void> _saveTargetWithoutProvider({
    required CosmeticFragmentProgress? progress,
  }) async {
    final required =
        progress?.requiredFragments ??
        CosmeticsService.dailyRunRequiredFragments;
    final target = CosmeticTarget(
      targetCosmeticItemId: widget.item.itemId,
      targetFragmentsOwned: (progress?.collectedFragments ?? 0)
          .clamp(0, required)
          .toInt(),
      targetFragmentsRequired: required <= 0
          ? CosmeticsService.dailyRunRequiredFragments
          : required,
      targetRarity: widget.item.rarity,
      targetItemName: widget.item.name,
      targetSlotLabel: widget.item.slotLabel,
      updatedAt: DateTime.now(),
    );
    await CosmeticTargetService.instance.saveTarget(target);
  }

  Future<void> _setTargetFromPreview({
    required CosmeticFragmentProgress? progress,
    required CosmeticTargetProvider? targetProvider,
  }) async {
    if (targetProvider != null) {
      await targetProvider.setTargetFromFlexItem(
        item: widget.item,
        progress: progress,
      );
    } else {
      await _saveTargetWithoutProvider(progress: progress);
    }
    await SoundService.instance.haptic(SoundHaptic.mediumImpact);
  }

  T? _maybeWatch<T>(BuildContext context) {
    try {
      return context.watch<T>();
    } catch (_) {
      return null;
    }
  }
}

class _DailyRunCta extends StatelessWidget {
  const _DailyRunCta({required this.label, required this.navigationContext});

  final String label;
  final BuildContext navigationContext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          const DailyReviewRoute().push(navigationContext);
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(label),
      ),
    );
  }
}

class _SetTargetButton extends StatefulWidget {
  const _SetTargetButton({
    required this.item,
    required this.progress,
    required this.targetProvider,
    required this.isCurrentTarget,
    required this.onSetWithoutProvider,
  });

  final SocialCosmeticFlexItem item;
  final CosmeticFragmentProgress? progress;
  final CosmeticTargetProvider? targetProvider;
  final bool isCurrentTarget;
  final Future<void> Function() onSetWithoutProvider;

  @override
  State<_SetTargetButton> createState() => _SetTargetButtonState();
}

class _SetTargetButtonState extends State<_SetTargetButton> {
  bool _saving = false;
  bool _justSet = false;

  @override
  Widget build(BuildContext context) {
    final color = CosmeticVisuals.rarityColor(widget.item.rarity);
    final isCurrent = widget.isCurrentTarget || _justSet;
    final label = isCurrent
        ? _justSet
              ? 'Target set'
              : 'Current target'
        : 'Set as target';

    return AnimatedScale(
      scale: _justSet ? 1.02 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const Key('set_cosmetic_target_button'),
          onPressed: isCurrent || _saving ? null : _setTarget,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isCurrent
                ? Icon(
                    Icons.check_circle_rounded,
                    key: const ValueKey('target-set'),
                    color: color,
                  )
                : _saving
                ? const SizedBox(
                    key: ValueKey('target-saving'),
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.gps_fixed_rounded,
                    key: const ValueKey('target-open'),
                    color: color,
                  ),
          ),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.55)),
          ),
        ),
      ),
    );
  }

  Future<void> _setTarget() async {
    setState(() => _saving = true);
    final provider = widget.targetProvider;
    if (provider != null) {
      await provider.setTargetFromFlexItem(
        item: widget.item,
        progress: widget.progress,
      );
    } else {
      await widget.onSetWithoutProvider();
    }
    await SoundService.instance.haptic(SoundHaptic.mediumImpact);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _justSet = true;
    });
  }
}

class _CosmeticPreview extends StatelessWidget {
  const _CosmeticPreview({required this.loadout, required this.color});

  final SocialCosmeticLoadout loadout;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: AvatarWidget(
        size: 70,
        showFrame: true,
        overrideConfig: loadout.toAvatarConfig('cosmetic-preview'),
        borderColor: color,
      ),
    );
  }
}

class _RarityPill extends StatelessWidget {
  const _RarityPill({required this.rarity});

  final CosmeticRarity rarity;

  @override
  Widget build(BuildContext context) {
    final color = CosmeticVisuals.rarityColor(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        rarity.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FragmentProgress extends StatelessWidget {
  const _FragmentProgress({required this.progress});

  final CosmeticFragmentProgress? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final collected = progress?.collectedFragments ?? 0;
    final required = progress?.requiredFragments ?? 5;
    final value = required <= 0 ? 0.0 : (collected / required).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                progress == null
                    ? 'Fragment progress: no fragments yet'
                    : 'Fragment progress: $collected / $required',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
