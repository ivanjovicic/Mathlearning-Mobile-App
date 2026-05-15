import 'cosmetic_item.dart';

class CosmeticTarget {
  const CosmeticTarget({
    required this.targetCosmeticItemId,
    required this.targetFragmentsOwned,
    required this.targetFragmentsRequired,
    required this.targetRarity,
    this.targetSetName,
    this.targetItemName,
    this.targetSlotLabel,
    this.bonusProgress = 0,
    this.updatedAt,
  });

  final String targetCosmeticItemId;
  final int targetFragmentsOwned;
  final int targetFragmentsRequired;
  final String? targetSetName;
  final CosmeticRarity targetRarity;
  final String? targetItemName;
  final String? targetSlotLabel;
  final int bonusProgress;
  final DateTime? updatedAt;

  /// Number of non-target runs needed to earn one bonus fragment.
  /// Each non-target run fills exactly 1 segment.
  static const int kBonusProgressMax = 5;

  bool get isComplete =>
      targetFragmentsRequired > 0 &&
      targetFragmentsOwned >= targetFragmentsRequired;

  int get remainingFragments =>
      (targetFragmentsRequired - targetFragmentsOwned).clamp(0, 999).toInt();

  double get progressValue {
    if (targetFragmentsRequired <= 0) return 0;
    return (targetFragmentsOwned / targetFragmentsRequired).clamp(0.0, 1.0);
  }

  /// Progress toward the next bonus fragment (0.0 – 1.0).
  double get bonusProgressValue =>
      (bonusProgress / kBonusProgressMax).clamp(0.0, 1.0);

  /// Whether there is any accumulated bonus progress to display.
  bool get hasBonusProgress => bonusProgress > 0;

  String get displayName {
    final itemName = targetItemName?.trim();
    if (itemName != null && itemName.isNotEmpty) return itemName;

    final setName = targetSetName?.trim();
    if (setName != null && setName.isNotEmpty) return setName;

    return _friendlyName(targetCosmeticItemId);
  }

  CosmeticTarget copyWith({
    String? targetCosmeticItemId,
    int? targetFragmentsOwned,
    int? targetFragmentsRequired,
    String? targetSetName,
    CosmeticRarity? targetRarity,
    String? targetItemName,
    String? targetSlotLabel,
    int? bonusProgress,
    DateTime? updatedAt,
  }) {
    return CosmeticTarget(
      targetCosmeticItemId: targetCosmeticItemId ?? this.targetCosmeticItemId,
      targetFragmentsOwned: targetFragmentsOwned ?? this.targetFragmentsOwned,
      targetFragmentsRequired:
          targetFragmentsRequired ?? this.targetFragmentsRequired,
      targetSetName: targetSetName ?? this.targetSetName,
      targetRarity: targetRarity ?? this.targetRarity,
      targetItemName: targetItemName ?? this.targetItemName,
      targetSlotLabel: targetSlotLabel ?? this.targetSlotLabel,
      bonusProgress: bonusProgress ?? this.bonusProgress,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CosmeticTarget.fromJson(Map<String, dynamic> json) {
    return CosmeticTarget(
      targetCosmeticItemId: _asString(
        json['targetCosmeticItemId'] ?? json['target_cosmetic_item_id'],
      ),
      targetFragmentsOwned:
          _asInt(
            json['targetFragmentsOwned'] ?? json['target_fragments_owned'],
          )?.clamp(0, 999).toInt() ??
          0,
      targetFragmentsRequired:
          _asInt(
            json['targetFragmentsRequired'] ??
                json['target_fragments_required'],
          )?.clamp(1, 999).toInt() ??
          5,
      targetSetName: _asNullableString(
        json['targetSetName'] ?? json['target_set_name'],
      ),
      targetRarity: CosmeticRarity.fromString(
        _asString(
          json['targetRarity'] ?? json['target_rarity'],
          fallback: 'common',
        ),
      ),
      targetItemName: _asNullableString(
        json['targetItemName'] ?? json['target_item_name'],
      ),
      targetSlotLabel: _asNullableString(
        json['targetSlotLabel'] ?? json['target_slot_label'],
      ),
      // Accepts both new key (bonusProgress) and old key (targetEnergy)
      // for backward compatibility with persisted local data.
      bonusProgress:
          _asInt(
            json['bonusProgress'] ?? json['bonus_progress'] ??
            json['targetEnergy'] ?? json['target_energy'],
          )?.clamp(0, kBonusProgressMax).toInt() ??
          0,
      updatedAt: DateTime.tryParse(
        _asString(json['updatedAt'] ?? json['updated_at']),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'targetCosmeticItemId': targetCosmeticItemId,
    'targetFragmentsOwned': targetFragmentsOwned,
    'targetFragmentsRequired': targetFragmentsRequired,
    'targetSetName': targetSetName,
    'targetRarity': targetRarity.name,
    'targetItemName': targetItemName,
    'targetSlotLabel': targetSlotLabel,
    'bonusProgress': bonusProgress,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

class CosmeticTargetProgressEvent {
  const CosmeticTargetProgressEvent({
    required this.target,
    required this.previousFragments,
    required this.currentFragments,
    required this.targetFragmentFound,
    this.bonusProgressAwarded = 0,
    this.bonusFragmentEarned = false,
  });

  final CosmeticTarget target;
  final int previousFragments;
  final int currentFragments;
  final bool targetFragmentFound;
  final int bonusProgressAwarded;

  /// True when this fragment was earned by crossing the bonus progress threshold
  /// (5 segments → +1 bonus fragment), not from a direct target drop.
  final bool bonusFragmentEarned;

  int get fragmentsGained =>
      (currentFragments - previousFragments).clamp(0, 999).toInt();

  bool get didComplete =>
      targetFragmentFound &&
      previousFragments < target.targetFragmentsRequired &&
      currentFragments >= target.targetFragmentsRequired;

  String get itemName => target.displayName;
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
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
