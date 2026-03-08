/// Rarity tiers for cosmetic items.
enum CosmeticRarity {
  common,
  rare,
  epic,
  legendary,
  mythic;

  String get label {
    switch (this) {
      case CosmeticRarity.common:
        return 'Common';
      case CosmeticRarity.rare:
        return 'Rare';
      case CosmeticRarity.epic:
        return 'Epic';
      case CosmeticRarity.legendary:
        return 'Legendary';
      case CosmeticRarity.mythic:
        return 'Mythic';
    }
  }

  static CosmeticRarity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'rare':
        return CosmeticRarity.rare;
      case 'epic':
        return CosmeticRarity.epic;
      case 'legendary':
        return CosmeticRarity.legendary;
      case 'mythic':
        return CosmeticRarity.mythic;
      default:
        return CosmeticRarity.common;
    }
  }
}

/// Visual categories of cosmetic items.
enum CosmeticCategory {
  avatarSkin,
  hairStyle,
  clothing,
  accessory,
  emojiReaction,
  avatarFrame,
  profileBackground,
  profileBadge,
  reactionSticker,
  animatedEffect;

  String get id {
    switch (this) {
      case CosmeticCategory.avatarSkin:
        return 'avatar_skin';
      case CosmeticCategory.hairStyle:
        return 'hair_style';
      case CosmeticCategory.clothing:
        return 'clothing';
      case CosmeticCategory.accessory:
        return 'accessory';
      case CosmeticCategory.emojiReaction:
        return 'emoji_reaction';
      case CosmeticCategory.avatarFrame:
        return 'avatar_frame';
      case CosmeticCategory.profileBackground:
        return 'profile_background';
      case CosmeticCategory.profileBadge:
        return 'profile_badge';
      case CosmeticCategory.reactionSticker:
        return 'reaction_sticker';
      case CosmeticCategory.animatedEffect:
        return 'animated_effect';
    }
  }

  String get label {
    switch (this) {
      case CosmeticCategory.avatarSkin:
        return 'Skin';
      case CosmeticCategory.hairStyle:
        return 'Frizura';
      case CosmeticCategory.clothing:
        return 'Odjeca';
      case CosmeticCategory.accessory:
        return 'Dodaci';
      case CosmeticCategory.emojiReaction:
        return 'Emoji';
      case CosmeticCategory.avatarFrame:
        return 'Okvir';
      case CosmeticCategory.profileBackground:
        return 'Pozadina';
      case CosmeticCategory.profileBadge:
        return 'Znacka';
      case CosmeticCategory.reactionSticker:
        return 'Nalepnice';
      case CosmeticCategory.animatedEffect:
        return 'Efekat';
    }
  }

  static CosmeticCategory fromId(String id) {
    for (final cat in CosmeticCategory.values) {
      if (cat.id == id) return cat;
    }
    return CosmeticCategory.avatarSkin;
  }
}

/// A single cosmetic item in the catalog.
class CosmeticItem {
  final String id;
  final String name;
  final CosmeticCategory category;
  final CosmeticRarity rarity;
  final String unlockCondition;
  /// Icon code point (for icon-based items) or asset path.
  final String assetKey;
  final String? seasonId;
  final bool isLimited;
  final DateTime createdAt;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    required this.unlockCondition,
    required this.assetKey,
    this.seasonId,
    this.isLimited = false,
    required this.createdAt,
  });

  factory CosmeticItem.fromJson(Map<String, dynamic> json) {
    return CosmeticItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: CosmeticCategory.fromId(json['category'] as String),
      rarity: CosmeticRarity.fromString(json['rarity'] as String),
      unlockCondition: json['unlock_condition'] as String? ?? '',
      assetKey: json['asset_key'] as String? ?? json['asset_path'] as String? ?? '',
      seasonId: json['season_id'] as String?,
      isLimited: (json['is_limited'] as bool?) ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.id,
        'rarity': rarity.name,
        'unlock_condition': unlockCondition,
        'asset_key': assetKey,
        'season_id': seasonId,
        'is_limited': isLimited,
        'created_at': createdAt.toIso8601String(),
      };
}
