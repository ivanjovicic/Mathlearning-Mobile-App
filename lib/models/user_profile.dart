import 'social_cosmetic_loadout.dart';

class UserProfile {
  final String id;
  final String username;
  final String email;
  final String displayName;
  final int coins;
  final int xp;
  final int level;
  final bool hasXp;
  final bool hasLevel;
  final String? avatarUrl;
  final SocialCosmeticLoadout? cosmeticLoadout;
  final int? schoolId;
  final int? facultyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    required this.coins,
    required this.xp,
    required this.level,
    this.hasXp = true,
    this.hasLevel = true,
    this.avatarUrl,
    this.cosmeticLoadout,
    this.schoolId,
    this.facultyId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    int? readNullableInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final xpValue = readNullableInt(json['xp']);
    final levelValue = readNullableInt(json['level']);

    return UserProfile(
      id: (json['id'] ?? json['userId'])?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? '',
      coins: json['coins'] ?? 100, // Default 100 coins for new users
      xp: xpValue ?? 0,
      level: levelValue ?? 1,
      hasXp: json.containsKey('xp') && xpValue != null,
      hasLevel: json.containsKey('level') && levelValue != null,
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      cosmeticLoadout: socialCosmeticLoadoutFromJson(json),
      schoolId: readNullableInt(json['schoolId'] ?? json['school_id']),
      facultyId: readNullableInt(json['facultyId'] ?? json['faculty_id']),
      createdAt:
          DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'displayName': displayName,
      'coins': coins,
      if (hasXp) 'xp': xp,
      if (hasLevel) 'level': level,
      'avatarUrl': avatarUrl,
      'cosmeticLoadout': cosmeticLoadout == null
          ? null
          : {
              'avatarFrameId': cosmeticLoadout!.avatarFrameId,
              'trailId': cosmeticLoadout!.trailId,
              'avatarGearId': cosmeticLoadout!.avatarGearId,
              'answerEffectId': cosmeticLoadout!.answerEffectId,
              'profileBackgroundId': cosmeticLoadout!.profileBackgroundId,
              'recentRareUnlocks': cosmeticLoadout!.recentRareUnlocks
                  .map(
                    (unlock) => {
                      'itemId': unlock.itemId,
                      'name': unlock.name,
                      'rarity': unlock.rarity.name,
                      'unlockedAt': unlock.unlockedAt?.toIso8601String(),
                    },
                  )
                  .toList(growable: false),
            },
      'schoolId': schoolId,
      'facultyId': facultyId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    int? coins,
    int? xp,
    int? level,
    bool? hasXp,
    bool? hasLevel,
    String? avatarUrl,
    SocialCosmeticLoadout? cosmeticLoadout,
    int? schoolId,
    int? facultyId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      hasXp: hasXp ?? this.hasXp,
      hasLevel: hasLevel ?? this.hasLevel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cosmeticLoadout: cosmeticLoadout ?? this.cosmeticLoadout,
      schoolId: schoolId ?? this.schoolId,
      facultyId: facultyId ?? this.facultyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, username: $username, displayName: $displayName, coins: $coins, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserSearchResult {
  final String id;
  final String username;
  final String displayName;
  final int level;
  final int xp;

  const UserSearchResult({
    required this.id,
    required this.username,
    required this.displayName,
    required this.level,
    required this.xp,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: (json['id'] ?? json['userId'])?.toString() ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? json['display_name'] ?? '',
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'level': level,
      'xp': xp,
    };
  }

  @override
  String toString() {
    return 'UserSearchResult(username: $username, displayName: $displayName, level: $level)';
  }
}
