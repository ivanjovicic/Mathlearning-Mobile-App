import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cosmetic_fragment_progress.dart';
import '../models/cosmetic_item.dart';
import '../models/cosmetic_target.dart';
import '../models/social_cosmetic_loadout.dart';
import '../services/cosmetic_target_service.dart';
import '../services/cosmetics_service.dart';

class CosmeticTargetProvider extends ChangeNotifier {
  CosmeticTargetProvider({CosmeticTargetService? service})
    : _service = service ?? CosmeticTargetService.instance;

  /// Each non-target run fills exactly 1 bonus progress segment.
  /// 5 segments = 1 bonus fragment.
  static const int bonusProgressPerRun = 1;

  final CosmeticTargetService _service;

  String? _userId;
  bool _isLoading = false;
  CosmeticTarget? _target;
  CosmeticTargetProgressEvent? _lastProgressEvent;

  bool get isLoading => _isLoading;
  CosmeticTarget? get target => _target;
  CosmeticTargetProgressEvent? get lastProgressEvent => _lastProgressEvent;

  void configureUser(String? userId, {bool autoLoad = true}) {
    final safeUserId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    if (_userId == safeUserId) return;
    _userId = safeUserId;
    _target = null;
    _lastProgressEvent = null;
    _isLoading = true;
    notifyListeners();
    if (autoLoad) {
      unawaited(_loadForUser(safeUserId));
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> load({String? userId}) async {
    final safeUserId = userId == null || userId.trim().isEmpty
        ? _userId ?? 'local'
        : userId.trim();
    _userId = safeUserId;
    _isLoading = true;
    notifyListeners();
    await _loadForUser(safeUserId);
  }

  Future<void> _loadForUser(String userId) async {
    final loaded = await _service.loadTarget(userId: userId);
    if (_userId != userId) return;
    _target = loaded;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTargetFromFlexItem({
    required SocialCosmeticFlexItem item,
    CosmeticFragmentProgress? progress,
  }) async {
    final now = DateTime.now();
    final owned = progress?.collectedFragments ?? 0;
    final required =
        progress?.requiredFragments ??
        CosmeticsService.dailyRunRequiredFragments;
    final target = CosmeticTarget(
      targetCosmeticItemId: item.itemId,
      targetFragmentsOwned: owned.clamp(0, required).toInt(),
      targetFragmentsRequired: required <= 0
          ? CosmeticsService.dailyRunRequiredFragments
          : required,
      targetRarity: item.rarity,
      targetItemName: item.name,
      targetSlotLabel: item.slotLabel,
      updatedAt: now,
    );
    await _save(target);
  }

  Future<void> setTargetFromCatalogItem({
    required CosmeticItem item,
    CosmeticFragmentProgress? progress,
  }) async {
    final now = DateTime.now();
    final required =
        progress?.requiredFragments ??
        CosmeticsService.dailyRunRequiredFragments;
    final target = CosmeticTarget(
      targetCosmeticItemId: item.id,
      targetFragmentsOwned: (progress?.collectedFragments ?? 0)
          .clamp(0, required)
          .toInt(),
      targetFragmentsRequired: required <= 0
          ? CosmeticsService.dailyRunRequiredFragments
          : required,
      targetRarity: item.rarity,
      targetItemName: item.name,
      targetSlotLabel: _slotLabelFor(item),
      updatedAt: now,
    );
    await _save(target);
  }

  // UI_PREVIEW_ONLY: Daily Run target progress here is for animation/preview, not final authority.
  Future<CosmeticTargetProgressEvent?> applyDailyRunGrant(
    DailyRunCosmeticGrantResult result,
  ) async {
    final current = _target;
    if (current == null) return null;

    final isTargetDrop = result.item.id == current.targetCosmeticItemId;
    if (!isTargetDrop) {
      final newProgress = current.bonusProgress + bonusProgressPerRun;
      final bonusEarned = newProgress >= CosmeticTarget.kBonusProgressMax;
      final storedProgress = bonusEarned
          ? (newProgress - CosmeticTarget.kBonusProgressMax)
                .clamp(0, CosmeticTarget.kBonusProgressMax)
                .toInt()
          : newProgress.clamp(0, CosmeticTarget.kBonusProgressMax).toInt();
      final newFragments = bonusEarned
          ? (current.targetFragmentsOwned + 1)
                .clamp(0, current.targetFragmentsRequired)
                .toInt()
          : current.targetFragmentsOwned;

      final updated = current.copyWith(
        bonusProgress: storedProgress,
        targetFragmentsOwned: newFragments,
        updatedAt: DateTime.now(),
      );
      await _save(updated);
      final event = CosmeticTargetProgressEvent(
        target: updated,
        previousFragments: current.targetFragmentsOwned,
        currentFragments: newFragments,
        targetFragmentFound: bonusEarned,
        bonusFragmentEarned: bonusEarned,
        bonusProgressAwarded: bonusProgressPerRun,
      );
      _lastProgressEvent = event;
      notifyListeners();
      // --- Reminder hook ---
      // When exactly 1 fragment remains, a local notification can be sent.
      // TODO(notifications): call NotificationService.scheduleTargetReminder(updated)
      // ignore: unnecessary_statements
      _maybeEmitReminderHook(updated);
      return event;
    }

    final previous = current.targetFragmentsOwned;
    final progress = result.progress;
    final updated = current.copyWith(
      targetFragmentsOwned: progress.collectedFragments
          .clamp(0, progress.requiredFragments)
          .toInt(),
      targetFragmentsRequired: progress.requiredFragments,
      targetRarity: result.item.rarity,
      targetItemName: result.item.name,
      targetSlotLabel: _slotLabelFor(result.item),
      updatedAt: progress.updatedAt,
    );
    await _save(updated);
    final event = CosmeticTargetProgressEvent(
      target: updated,
      previousFragments: previous,
      currentFragments: updated.targetFragmentsOwned,
      targetFragmentFound: true,
    );
    _lastProgressEvent = event;
    notifyListeners();
    _maybeEmitReminderHook(updated);
    return event;
  }

  Future<void> refreshFromFragmentProgress() async {
    final current = _target;
    if (current == null) return;
    // LOCAL_AUTHORITY_TODO: cosmetic target refresh currently reconciles from
    // local fragment progress cache; backend target progress should replace it.
    final progress = await CosmeticsService.instance.loadFragmentProgress();
    final match = progress
        .where((entry) => entry.itemId == current.targetCosmeticItemId)
        .firstOrNull;
    if (match == null) return;

    await _save(
      current.copyWith(
        targetFragmentsOwned: match.collectedFragments,
        targetFragmentsRequired: match.requiredFragments,
        updatedAt: match.updatedAt,
      ),
    );
  }

  Future<void> clearTarget() async {
    final userId = _userId ?? 'local';
    _target = null;
    _lastProgressEvent = null;
    notifyListeners();
    await _service.clearTarget(userId: userId);
  }

  void clearLastProgressEvent() {
    if (_lastProgressEvent == null) return;
    _lastProgressEvent = null;
    notifyListeners();
  }

  Future<void> _save(CosmeticTarget target) async {
    final userId = _userId ?? 'local';
    _target = target;
    notifyListeners();
    await _service.saveTarget(target, userId: userId);
  }

  String _slotLabelFor(CosmeticItem item) {
    return switch (item.category) {
      CosmeticCategory.avatarFrame => 'Frame',
      CosmeticCategory.animatedEffect =>
        item.id.contains('trail') ? 'Trail' : 'Effect',
      CosmeticCategory.accessory ||
      CosmeticCategory.avatarSkin ||
      CosmeticCategory.hairStyle ||
      CosmeticCategory.clothing => 'Gear',
      CosmeticCategory.profileBackground => 'Background',
      _ => item.category.label,
    };
  }

  /// Called whenever the target is updated after a run.
  /// Exposes a hook for future local notification scheduling:
  ///   - If remainingFragments == 1, notify "1 Daily Run away from [item]!"
  ///
  /// TODO(notifications): replace body with a real
  ///   NotificationService.scheduleTargetReminder(target) call once the
  ///   notification infrastructure is in place.
  void _maybeEmitReminderHook(CosmeticTarget target) {
    if (target.remainingFragments == 1) {
      // Hook point — 1 fragment remaining. Integrate notification here.
      assert(
        true,
        'Reminder: 1 fragment away from ${target.displayName}. '
        'Wire NotificationService here.',
      );
    }
  }
}
