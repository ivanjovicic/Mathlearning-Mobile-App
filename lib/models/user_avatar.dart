/// The equipped avatar configuration for a user.
/// Stores which cosmetic item is equipped in each slot.
class UserAvatar {
  final String userId;
  final String? skinId;
  final String? hairId;
  final String? clothingId;
  final String? accessoryId;
  final String? emojiId;
  final String? frameId;
  final String? backgroundId;
  final DateTime updatedAt;

  const UserAvatar({
    required this.userId,
    this.skinId,
    this.hairId,
    this.clothingId,
    this.accessoryId,
    this.emojiId,
    this.frameId,
    this.backgroundId,
    required this.updatedAt,
  });

  factory UserAvatar.defaults(String userId) => UserAvatar(
        userId: userId,
        skinId: 'skin_default',
        hairId: 'hair_default',
        clothingId: 'clothing_default',
        accessoryId: null,
        emojiId: 'emoji_default',
        frameId: null,
        backgroundId: 'bg_default',
        updatedAt: DateTime.now(),
      );

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      userId: (json['user_id'] ?? json['userId'])?.toString() ?? '',
      skinId: json['skin_id'] as String?,
      hairId: json['hair_id'] as String?,
      clothingId: json['clothing_id'] as String?,
      accessoryId: json['accessory_id'] as String?,
      emojiId: json['emoji_id'] as String?,
      frameId: json['frame_id'] as String?,
      backgroundId: json['background_id'] as String?,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'skin_id': skinId,
        'hair_id': hairId,
        'clothing_id': clothingId,
        'accessory_id': accessoryId,
        'emoji_id': emojiId,
        'frame_id': frameId,
        'background_id': backgroundId,
        'updated_at': updatedAt.toIso8601String(),
      };

  UserAvatar copyWith({
    String? skinId,
    String? hairId,
    String? clothingId,
    String? accessoryId,
    String? emojiId,
    String? frameId,
    String? backgroundId,
    bool clearSkin = false,
    bool clearHair = false,
    bool clearClothing = false,
    bool clearAccessory = false,
    bool clearEmoji = false,
    bool clearFrame = false,
    bool clearBackground = false,
  }) {
    return UserAvatar(
      userId: userId,
      skinId: clearSkin ? null : (skinId ?? this.skinId),
      hairId: clearHair ? null : (hairId ?? this.hairId),
      clothingId: clearClothing ? null : (clothingId ?? this.clothingId),
      accessoryId: clearAccessory ? null : (accessoryId ?? this.accessoryId),
      emojiId: clearEmoji ? null : (emojiId ?? this.emojiId),
      frameId: clearFrame ? null : (frameId ?? this.frameId),
      backgroundId: clearBackground ? null : (backgroundId ?? this.backgroundId),
      updatedAt: DateTime.now(),
    );
  }

  /// Returns the equipped item id for the given slot category.
  String? slotFor(String categoryId) {
    switch (categoryId) {
      case 'avatar_skin':
        return skinId;
      case 'hair_style':
        return hairId;
      case 'clothing':
        return clothingId;
      case 'accessory':
        return accessoryId;
      case 'emoji_reaction':
        return emojiId;
      case 'avatar_frame':
        return frameId;
      case 'profile_background':
        return backgroundId;
      default:
        return null;
    }
  }
}
