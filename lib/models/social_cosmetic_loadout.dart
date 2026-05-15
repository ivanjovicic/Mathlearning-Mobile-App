import 'cosmetic_item.dart';
import 'user_avatar.dart';
import 'user_cosmetic.dart';

class SocialCosmeticUnlock {
  const SocialCosmeticUnlock({
    required this.itemId,
    required this.name,
    required this.rarity,
    this.unlockedAt,
    this.hasActualName = true,
  });

  final String itemId;
  final String name;
  final CosmeticRarity rarity;
  final DateTime? unlockedAt;
  final bool hasActualName;

  factory SocialCosmeticUnlock.fromJson(Map<String, dynamic> json) {
    final itemId = _asString(json['itemId'] ?? json['item_id'] ?? json['id']);
    final actualName = _asNullableString(
      json['name'] ?? json['itemName'] ?? json['item_name'],
    );
    return SocialCosmeticUnlock(
      itemId: itemId,
      name: actualName ?? _friendlyName(itemId),
      rarity: CosmeticRarity.fromString(
        _asString(json['rarity'], fallback: 'common'),
      ),
      unlockedAt: DateTime.tryParse(
        _asString(json['unlockedAt'] ?? json['unlocked_at']),
      ),
      hasActualName: actualName != null,
    );
  }
}

class SocialCosmeticFlexItem {
  const SocialCosmeticFlexItem({
    required this.itemId,
    required this.name,
    required this.rarity,
    required this.slotLabel,
    required this.hasActualName,
  });

  final String itemId;
  final String name;
  final CosmeticRarity rarity;
  final String slotLabel;
  final bool hasActualName;
}

class SocialCosmeticLoadout {
  const SocialCosmeticLoadout({
    this.avatarFrameId,
    this.highlightRarity,
    String? trailId,
    String? avatarGearId,
    this.answerEffectId,
    this.profileBackgroundId,
    List<SocialCosmeticUnlock>? recentRareUnlocks,
    @Deprecated('Use trailId instead.') String? animatedEffectId,
    @Deprecated('Use avatarGearId instead.') String? accessoryId,
    @Deprecated('Use recentRareUnlocks instead.')
    List<SocialCosmeticUnlock>? recentUnlocks,
  }) : trailId = trailId ?? animatedEffectId,
       avatarGearId = avatarGearId ?? accessoryId,
       recentRareUnlocks =
           recentRareUnlocks ?? recentUnlocks ?? const <SocialCosmeticUnlock>[];

  final String? avatarFrameId;
  final String? trailId;
  final String? avatarGearId;
  final String? answerEffectId;
  final String? profileBackgroundId;
  final CosmeticRarity? highlightRarity;
  final List<SocialCosmeticUnlock> recentRareUnlocks;

  @Deprecated('Use trailId instead.')
  String? get animatedEffectId => trailId ?? answerEffectId;

  @Deprecated('Use avatarGearId instead.')
  String? get accessoryId => avatarGearId;

  @Deprecated('Use recentRareUnlocks instead.')
  List<SocialCosmeticUnlock> get recentUnlocks => recentRareUnlocks;

  bool get hasEquippedCosmetics =>
      avatarFrameId != null ||
      trailId != null ||
      avatarGearId != null ||
      answerEffectId != null ||
      profileBackgroundId != null;

  bool get hasRecentRareUnlock => recentRareUnlocks.isNotEmpty;

  bool get isEmpty =>
      !hasEquippedCosmetics && !hasRecentRareUnlock && highlightRarity == null;

  /// Human-readable names for equipped slots, derived from item IDs.
  /// Prefers name from recentRareUnlocks catalog; falls back to friendly ID.
  /// Returns empty list when nothing is equipped.
  List<({String name, CosmeticRarity? rarity})> get equippedItemLabels {
    final result = <({String name, CosmeticRarity? rarity})>[];
    if (avatarFrameId != null) {
      final match = recentRareUnlocks
          .where((u) => u.itemId == avatarFrameId)
          .firstOrNull;
      result.add((
        name: match?.name ?? _friendlyName(avatarFrameId!),
        rarity: match?.rarity,
      ));
    }
    if (trailId != null) {
      final match = recentRareUnlocks
          .where((u) => u.itemId == trailId)
          .firstOrNull;
      result.add((
        name: match?.name ?? _friendlyName(trailId!),
        rarity: match?.rarity,
      ));
    }
    if (avatarGearId != null) {
      final match = recentRareUnlocks
          .where((u) => u.itemId == avatarGearId)
          .firstOrNull;
      result.add((
        name: match?.name ?? _friendlyName(avatarGearId!),
        rarity: match?.rarity,
      ));
    }
    if (answerEffectId != null) {
      final match = recentRareUnlocks
          .where((u) => u.itemId == answerEffectId)
          .firstOrNull;
      result.add((
        name: match?.name ?? _friendlyName(answerEffectId!),
        rarity: match?.rarity,
      ));
    }
    if (profileBackgroundId != null) {
      final match = recentRareUnlocks
          .where((u) => u.itemId == profileBackgroundId)
          .firstOrNull;
      result.add((
        name: match?.name ?? _friendlyName(profileBackgroundId!),
        rarity: match?.rarity,
      ));
    }
    return result;
  }

  SocialCosmeticFlexItem? get flexItem {
    return flexItemWithCatalog(const <CosmeticItem>[]);
  }

  SocialCosmeticFlexItem? flexItemWithCatalog(List<CosmeticItem> catalog) {
    final catalogById = {for (final item in catalog) item.id: item};
    final candidates = <({int priority, SocialCosmeticFlexItem item})>[
      ?_flexCandidate(
        itemId: avatarFrameId,
        slotLabel: 'Frame',
        priority: 0,
        catalogById: catalogById,
      ),
      ?_flexCandidate(
        itemId: trailId,
        slotLabel: 'Trail',
        priority: 1,
        catalogById: catalogById,
      ),
      ?_flexCandidate(
        itemId: avatarGearId,
        slotLabel: 'Gear',
        priority: 2,
        catalogById: catalogById,
      ),
      ?_flexCandidate(
        itemId: answerEffectId,
        slotLabel: 'Effect',
        priority: 3,
        catalogById: catalogById,
      ),
      ?_flexCandidate(
        itemId: profileBackgroundId,
        slotLabel: 'Background',
        priority: 4,
        catalogById: catalogById,
      ),
    ];
    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      if (priority != 0) return priority;
      return b.item.rarity.index.compareTo(a.item.rarity.index);
    });
    return candidates.first.item;
  }

  ({int priority, SocialCosmeticFlexItem item})? _flexCandidate({
    required String? itemId,
    required String slotLabel,
    required int priority,
    required Map<String, CosmeticItem> catalogById,
  }) {
    if (itemId == null) return null;

    return (
      priority: priority,
      item: _buildFlexItem(
        itemId: itemId,
        slotLabel: slotLabel,
        catalogById: catalogById,
      ),
    );
  }

  SocialCosmeticFlexItem _buildFlexItem({
    required String itemId,
    required String slotLabel,
    required Map<String, CosmeticItem> catalogById,
  }) {
    final unlock = recentRareUnlocks
        .where((entry) => entry.itemId == itemId)
        .firstOrNull;
    final catalogItem = catalogById[itemId];
    final rarity =
        unlock?.rarity ??
        catalogItem?.rarity ??
        highlightRarity ??
        _rarityFromItemId(itemId);
    final actualName = unlock?.hasActualName == true
        ? unlock!.name
        : catalogItem?.name;

    return SocialCosmeticFlexItem(
      itemId: itemId,
      name: actualName ?? _fallbackFlexName(rarity, slotLabel),
      rarity: rarity,
      slotLabel: slotLabel,
      hasActualName: actualName != null,
    );
  }

  CosmeticRarity? get strongestRarity {
    final rarities = <CosmeticRarity>[
      ?highlightRarity,
      for (final unlock in recentRareUnlocks) unlock.rarity,
    ];
    if (rarities.isEmpty) return null;
    rarities.sort((a, b) => b.index.compareTo(a.index));
    return rarities.first;
  }

  UserAvatar toAvatarConfig(String userId) {
    return UserAvatar.defaults(userId).copyWith(
      frameId: avatarFrameId,
      accessoryId: avatarGearId,
      backgroundId: profileBackgroundId,
      animatedEffectId: trailId ?? answerEffectId,
    );
  }

  factory SocialCosmeticLoadout.fromJson(Map<String, dynamic> json) {
    final recentRaw =
        json['recentRareUnlocks'] ??
        json['recent_rare_unlocks'] ??
        json['recentUnlocks'] ??
        json['recent_unlocks'] ??
        json['unlocks'];
    final recent = recentRaw is List
        ? recentRaw
              .map((entry) {
                if (entry is String) {
                  return SocialCosmeticUnlock(
                    itemId: entry,
                    name: _friendlyName(entry),
                    rarity: _rarityFromItemId(entry),
                    hasActualName: false,
                  );
                }
                if (entry is Map) {
                  return SocialCosmeticUnlock.fromJson(
                    Map<String, dynamic>.from(entry),
                  );
                }
                return null;
              })
              .whereType<SocialCosmeticUnlock>()
              .toList(growable: false)
        : const <SocialCosmeticUnlock>[];

    return SocialCosmeticLoadout(
      avatarFrameId: _asNullableString(
        json['avatarFrameId'] ??
            json['avatar_frame_id'] ??
            json['frameId'] ??
            json['frame_id'],
      ),
      trailId: _asNullableString(
        json['trailId'] ??
            json['trail_id'] ??
            json['animatedEffectId'] ??
            json['animated_effect_id'],
      ),
      avatarGearId: _asNullableString(
        json['avatarGearId'] ??
            json['avatar_gear_id'] ??
            json['accessoryId'] ??
            json['accessory_id'] ??
            json['gearId'] ??
            json['gear_id'],
      ),
      answerEffectId: _asNullableString(
        json['answerEffectId'] ??
            json['answer_effect_id'] ??
            json['effectId'] ??
            json['effect_id'],
      ),
      profileBackgroundId: _asNullableString(
        json['profileBackgroundId'] ??
            json['profile_background_id'] ??
            json['backgroundId'] ??
            json['background_id'],
      ),
      highlightRarity:
          _rarityFromNullableString(
            _asNullableString(
              json['highlightRarity'] ??
                  json['highlight_rarity'] ??
                  json['glowRarity'] ??
                  json['glow_rarity'] ??
                  json['rarity'],
            ),
          ) ??
          (recent.isEmpty ? null : recent.first.rarity),
      recentRareUnlocks: recent,
    );
  }

  factory SocialCosmeticLoadout.fromLocal({
    required String userId,
    required UserAvatar? avatar,
    required List<UserCosmetic> inventory,
    required List<CosmeticItem> catalog,
  }) {
    final catalogById = {for (final item in catalog) item.id: item};
    final recent =
        inventory
            .map((entry) {
              final item = catalogById[entry.itemId];
              if (item == null ||
                  item.rarity.index < CosmeticRarity.rare.index) {
                return null;
              }
              return SocialCosmeticUnlock(
                itemId: item.id,
                name: item.name,
                rarity: item.rarity,
                unlockedAt: entry.unlockedAt,
              );
            })
            .whereType<SocialCosmeticUnlock>()
            .toList()
          ..sort((a, b) {
            final aTime =
                a.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.unlockedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

    return SocialCosmeticLoadout(
      avatarFrameId: avatar?.frameId,
      trailId: avatar?.animatedEffectId,
      avatarGearId: avatar?.accessoryId,
      profileBackgroundId: _nonDefaultId(avatar?.backgroundId, 'bg_default'),
      highlightRarity: recent.isEmpty ? null : recent.first.rarity,
      recentRareUnlocks: recent.take(5).toList(growable: false),
    );
  }
}

SocialCosmeticLoadout? socialCosmeticLoadoutFromJson(
  Map<String, dynamic> json,
) {
  final raw =
      json['cosmetics'] ??
      json['cosmeticLoadout'] ??
      json['cosmetic_loadout'] ??
      json['equippedCosmetics'] ??
      json['equipped_cosmetics'];
  if (raw is Map) {
    return SocialCosmeticLoadout.fromJson(Map<String, dynamic>.from(raw));
  }
  if (_hasLoadoutFields(json)) {
    return SocialCosmeticLoadout.fromJson(json);
  }
  return null;
}

bool _hasLoadoutFields(Map<String, dynamic> json) {
  const keys = <String>{
    'avatarFrameId',
    'avatar_frame_id',
    'frameId',
    'frame_id',
    'trailId',
    'trail_id',
    'avatarGearId',
    'avatar_gear_id',
    'answerEffectId',
    'answer_effect_id',
    'profileBackgroundId',
    'profile_background_id',
    'recentRareUnlocks',
    'recent_rare_unlocks',
    'animatedEffectId',
    'animated_effect_id',
    'accessoryId',
    'accessory_id',
    'gearId',
    'gear_id',
    'recentUnlocks',
    'recent_unlocks',
  };
  return keys.any(json.containsKey);
}

String _asString(dynamic value, {String fallback = ''}) {
  final safe = value?.toString().trim();
  if (safe == null || safe.isEmpty) return fallback;
  return safe;
}

String? _asNullableString(dynamic value) {
  final safe = value?.toString().trim();
  if (safe == null || safe.isEmpty) return null;
  return safe;
}

String? _nonDefaultId(String? value, String defaultValue) {
  if (value == null || value == defaultValue) return null;
  return value;
}

CosmeticRarity? _rarityFromNullableString(String? value) {
  if (value == null) return null;
  return CosmeticRarity.fromString(value);
}

CosmeticRarity _rarityFromItemId(String itemId) {
  if (itemId.contains('legend') || itemId.contains('gold')) {
    return CosmeticRarity.legendary;
  }
  if (itemId.contains('epic') ||
      itemId.contains('neon') ||
      itemId.contains('olympiad')) {
    return CosmeticRarity.epic;
  }
  if (itemId.contains('rare') || itemId.contains('comet')) {
    return CosmeticRarity.rare;
  }
  return CosmeticRarity.common;
}

String _friendlyName(String itemId) {
  return itemId
      .replaceAll(
        RegExp(r'^(frame|effect|acc|skin|hair|clothing|trail|gear|bg)_'),
        '',
      )
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _fallbackFlexName(CosmeticRarity rarity, String slotLabel) {
  return '${rarity.label} $slotLabel';
}
