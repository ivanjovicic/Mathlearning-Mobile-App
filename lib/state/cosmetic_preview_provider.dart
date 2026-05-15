import 'package:flutter/foundation.dart';

import '../models/social_cosmetic_loadout.dart';
import '../models/user_avatar.dart';

class CosmeticPreviewProvider extends ChangeNotifier {
  String? _userId;
  SocialCosmeticFlexItem? _previewItem;

  String? get userId => _userId;
  SocialCosmeticFlexItem? get previewItem => _previewItem;
  bool get isPreviewing => _previewItem != null;

  void configureUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    if (_previewItem != null) {
      _previewItem = null;
      notifyListeners();
    }
  }

  void startPreview(SocialCosmeticFlexItem item) {
    final current = _previewItem;
    if (current != null &&
        current.itemId == item.itemId &&
        current.slotLabel == item.slotLabel &&
        current.name == item.name &&
        current.rarity == item.rarity) {
      return;
    }
    _previewItem = item;
    notifyListeners();
  }

  void clearPreview() {
    if (_previewItem == null) return;
    _previewItem = null;
    notifyListeners();
  }

  bool isPreviewingItem(String itemId) => _previewItem?.itemId == itemId;

  UserAvatar applyToAvatar(UserAvatar? baseAvatar, {String? fallbackUserId}) {
    final item = _previewItem;
    final userId = baseAvatar?.userId ?? fallbackUserId ?? _userId ?? 'local';
    final base = baseAvatar ?? UserAvatar.defaults(userId);
    if (item == null) return base;
    return applyPreviewItemToAvatar(base, item);
  }

  SocialCosmeticLoadout applyToLoadout(SocialCosmeticLoadout? baseLoadout) {
    final item = _previewItem;
    final base = baseLoadout ?? const SocialCosmeticLoadout();
    if (item == null) return base;
    return applyPreviewItemToLoadout(base, item);
  }

  SocialCosmeticLoadout? previewLoadoutForActiveItem() {
    final item = _previewItem;
    if (item == null) return null;
    return previewLoadoutForItem(item);
  }
}

UserAvatar applyPreviewItemToAvatar(
  UserAvatar base,
  SocialCosmeticFlexItem item,
) {
  switch (_slotForItem(item)) {
    case _PreviewSlot.frame:
      return base.copyWith(frameId: item.itemId);
    case _PreviewSlot.background:
      return base.copyWith(backgroundId: item.itemId);
    case _PreviewSlot.trail:
    case _PreviewSlot.answerEffect:
      return base.copyWith(animatedEffectId: item.itemId);
    case _PreviewSlot.gear:
      return base.copyWith(accessoryId: item.itemId);
    case _PreviewSlot.unknown:
      return base;
  }
}

SocialCosmeticLoadout applyPreviewItemToLoadout(
  SocialCosmeticLoadout base,
  SocialCosmeticFlexItem item,
) {
  final slot = _slotForItem(item);
  return SocialCosmeticLoadout(
    avatarFrameId: slot == _PreviewSlot.frame
        ? item.itemId
        : base.avatarFrameId,
    trailId: slot == _PreviewSlot.trail ? item.itemId : base.trailId,
    avatarGearId: slot == _PreviewSlot.gear
        ? item.itemId
        : base.avatarGearId,
    answerEffectId: slot == _PreviewSlot.answerEffect
        ? item.itemId
        : base.answerEffectId,
    profileBackgroundId: slot == _PreviewSlot.background
        ? item.itemId
        : base.profileBackgroundId,
    highlightRarity: item.rarity,
    recentRareUnlocks: base.recentRareUnlocks,
  );
}

SocialCosmeticLoadout previewLoadoutForItem(SocialCosmeticFlexItem item) {
  switch (_slotForItem(item)) {
    case _PreviewSlot.frame:
      return SocialCosmeticLoadout(
        avatarFrameId: item.itemId,
        highlightRarity: item.rarity,
      );
    case _PreviewSlot.background:
      return SocialCosmeticLoadout(
        profileBackgroundId: item.itemId,
        highlightRarity: item.rarity,
      );
    case _PreviewSlot.trail:
      return SocialCosmeticLoadout(
        trailId: item.itemId,
        highlightRarity: item.rarity,
      );
    case _PreviewSlot.answerEffect:
      return SocialCosmeticLoadout(
        answerEffectId: item.itemId,
        highlightRarity: item.rarity,
      );
    case _PreviewSlot.gear:
      return SocialCosmeticLoadout(
        avatarGearId: item.itemId,
        highlightRarity: item.rarity,
      );
    case _PreviewSlot.unknown:
      return SocialCosmeticLoadout(highlightRarity: item.rarity);
  }
}

bool isPreviewEffectLike(SocialCosmeticFlexItem item) {
  final slot = _slotForItem(item);
  return slot == _PreviewSlot.trail || slot == _PreviewSlot.answerEffect;
}

bool isPreviewBackgroundLike(SocialCosmeticFlexItem item) {
  return _slotForItem(item) == _PreviewSlot.background;
}

enum _PreviewSlot { frame, trail, answerEffect, background, gear, unknown }

_PreviewSlot _slotForItem(SocialCosmeticFlexItem item) {
  final slot = item.slotLabel.trim().toLowerCase();
  final itemId = item.itemId;
  if (itemId.startsWith('frame_') || slot == 'frame') {
    return _PreviewSlot.frame;
  }
  if (itemId.startsWith('bg_') || slot == 'background') {
    return _PreviewSlot.background;
  }
  if (itemId.startsWith('trail_') || slot == 'trail') {
    return _PreviewSlot.trail;
  }
  if (itemId.startsWith('effect_') || slot == 'effect') {
    return _PreviewSlot.answerEffect;
  }
  if (itemId.startsWith('acc_') ||
      itemId.startsWith('gear_') ||
      slot == 'gear' ||
      slot == 'accessory') {
    return _PreviewSlot.gear;
  }
  return _PreviewSlot.unknown;
}