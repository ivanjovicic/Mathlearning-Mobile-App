/// A cosmetic item that has been unlocked and is in the user's inventory.
class UserCosmetic {
  final String id;
  final String userId;
  final String itemId;
  final DateTime unlockedAt;
  /// Source that granted this item: 'level_up', 'achievement', 'leaderboard',
  /// 'event', 'season', 'starter', 'manual'.
  final String sourceType;
  final String? sourceEvent;

  const UserCosmetic({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.unlockedAt,
    required this.sourceType,
    this.sourceEvent,
  });

  factory UserCosmetic.fromJson(Map<String, dynamic> json) {
    return UserCosmetic(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] ?? json['userId'])?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      unlockedAt:
          DateTime.tryParse(json['unlocked_at'] as String? ?? '') ??
          DateTime.now(),
      sourceType: json['source_type'] as String? ?? 'manual',
      sourceEvent: json['source_event'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'item_id': itemId,
        'unlocked_at': unlockedAt.toIso8601String(),
        'source_type': sourceType,
        'source_event': sourceEvent,
      };
}
