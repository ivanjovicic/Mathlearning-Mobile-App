import 'cosmetic_item.dart';
import 'user_avatar.dart';
import 'user_cosmetic.dart';

class SocialCosmeticUnlock {
  const SocialCosmeticUnlock({
    required this.itemId,
    required this.name,
    required this.rarity,
    this.unlockedAt,
  });

  final String itemId;
  final String name;
  final CosmeticRarity rarity;
  final DateTime? unlockedAt;

  factory SocialCosmeticUnlock.fromJson(Map<String, dynamic> json) {
    return SocialCosmeticUnlock(
      itemId: _asString(json['itemId'] ?? json['item_id'] ?? json['id']),
      name: _asString(json['name'] ?? json['itemName'] ?? json['item_name']),
      rarity: CosmeticRarity.fromString(
        _asString(json['rarity'], fallback: 'common'),
      ),
      unlockedAt: DateTime.tryParse(
        _asString(json['unlockedAt'] ?? json['unlocked_at']),
      ),
    );
  }
}

class SocialCosmeticLoadout {
  const SocialCosmeticLoadout({
    this.avatarFrameId,
    this.animatedEffectId,
    this.accessoryId,
    this.highlightRarity,
    this.recentUnlocks = const <SocialCosmeticUnlock>[],
  });

  final String? avatarFrameId;
  final String? animatedEffectId;
  final String? accessoryId;
  final CosmeticRarity? highlightRarity;
  final List<SocialCosmeticUnlock> recentUnlocks;

  bool get hasEquippedCosmetics =>
      avatarFrameId != null || animatedEffectId != null || accessoryId != null;

  bool get hasRecentRareUnlock => recentUnlocks.any(
    (unlock) => unlock.rarity.index >= CosmeticRarity.rare.index,
  );

  bool get isEmpty =>
      !hasEquippedCosmetics && !hasRecentRareUnlock && highlightRarity == null;

  /// Human-readable names for equipped slots, derived from item IDs.
  /// Prefers name from recentUnlocks catalog; falls back to friendly ID.
  /// Returns empty list when nothing is equipped.
  List<({String name, CosmeticRarity? rarity})> get equippedItemLabels {
    final result = <({String name, CosmeticRarity? rarity})>[];
    if (avatarFrameId != null) {
      final match = recentUnlocks
          .where((u) => u.itemId == avatarFrameId)
          .firstOrNull;
      result.add((
        name: match?.name ?? _friendlyName(avatarFrameId!),
        rarity: match?.rarity,
      ));
    }
    if (animatedEffectId != null) {
      final match = recentUnlocks
          .where((u) => u.itemId == animatedEffectId)
          .firstOrNull;
      result.add((
        name: match?.name ?? _friendlyName(animatedEffectId!),
        rarity: match?.rarity,
      ));
    }
    if (accessoryId != null) {
      final match = recentUnlocks
          .where((u) => u.itemId == accessoryId)
          .firstOrNull;
      result.add((
        name: match?.name ?? _friendlyName(accessoryId!),
        rarity: match?.rarity,
      ));
    }
    return result;
  }

  CosmeticRarity? get strongestRarity {
    final rarities = <CosmeticRarity>[
      ?highlightRarity,
      for (final unlock in recentUnlocks) unlock.rarity,
    ];
    if (rarities.isEmpty) return null;
    rarities.sort((a, b) => b.index.compareTo(a.index));
    return rarities.first;
  }

  UserAvatar toAvatarConfig(String userId) {
    return UserAvatar.defaults(userId).copyWith(
      frameId: avatarFrameId,
      accessoryId: accessoryId,
      animatedEffectId: animatedEffectId,
    );
  }

  factory SocialCosmeticLoadout.fromJson(Map<String, dynamic> json) {
    final recentRaw =
        json['recentUnlocks'] ?? json['recent_unlocks'] ?? json['unlocks'];
    final recent = recentRaw is List
        ? recentRaw
              .map((entry) {
                if (entry is String) {
                  return SocialCosmeticUnlock(
                    itemId: entry,
                    name: _friendlyName(entry),
                    rarity: _rarityFromItemId(entry),
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
      animatedEffectId: _asNullableString(
        json['animatedEffectId'] ??
            json['animated_effect_id'] ??
            json['effectId'] ??
            json['effect_id'] ??
            json['trailId'] ??
            json['trail_id'],
      ),
      accessoryId: _asNullableString(
        json['accessoryId'] ??
            json['accessory_id'] ??
            json['gearId'] ??
            json['gear_id'],
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
      recentUnlocks: recent,
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
      animatedEffectId: avatar?.animatedEffectId,
      accessoryId: avatar?.accessoryId,
      highlightRarity: recent.isEmpty ? null : recent.first.rarity,
      recentUnlocks: recent.take(5).toList(growable: false),
    );
  }

  factory SocialCosmeticLoadout.mockForLeaderboard({
    required int rank,
    required int userId,
  }) {
    if (rank == 1) {
      return const SocialCosmeticLoadout(
        avatarFrameId: 'frame_gold_laurel',
        animatedEffectId: 'effect_neon_number_burst',
        highlightRarity: CosmeticRarity.legendary,
        recentUnlocks: [
          SocialCosmeticUnlock(
            itemId: 'effect_neon_number_burst',
            name: 'Neon Number Burst',
            rarity: CosmeticRarity.epic,
          ),
        ],
      );
    }
    if (rank == 2) {
      return const SocialCosmeticLoadout(
        avatarFrameId: 'frame_olympiad',
        accessoryId: 'acc_math_crown',
        highlightRarity: CosmeticRarity.epic,
      );
    }
    if (rank == 3 || userId % 7 == 0) {
      return const SocialCosmeticLoadout(
        avatarFrameId: 'frame_comet',
        animatedEffectId: 'effect_nova_trail',
        highlightRarity: CosmeticRarity.rare,
        recentUnlocks: [
          SocialCosmeticUnlock(
            itemId: 'frame_comet',
            name: 'Comet Frame',
            rarity: CosmeticRarity.rare,
          ),
        ],
      );
    }
    return const SocialCosmeticLoadout();
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
  return null;
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
      .replaceAll(RegExp(r'^(frame|effect|acc|skin|hair|clothing)_'), '')
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}
