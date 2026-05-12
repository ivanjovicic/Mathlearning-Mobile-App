import 'cosmetic_item.dart';
import 'user_cosmetic.dart';

class CosmeticFragmentProgress {
  const CosmeticFragmentProgress({
    required this.itemId,
    required this.collectedFragments,
    required this.requiredFragments,
    required this.updatedAt,
    this.unlockedAt,
  });

  final String itemId;
  final int collectedFragments;
  final int requiredFragments;
  final DateTime updatedAt;
  final DateTime? unlockedAt;

  bool get isUnlocked => collectedFragments >= requiredFragments;

  factory CosmeticFragmentProgress.fromJson(Map<String, dynamic> json) {
    return CosmeticFragmentProgress(
      itemId: (json['item_id'] ?? json['itemId'])?.toString() ?? '',
      collectedFragments:
          _asInt(json['collected_fragments'] ?? json['collectedFragments']) ??
          0,
      requiredFragments:
          _asInt(json['required_fragments'] ?? json['requiredFragments']) ?? 5,
      updatedAt:
          DateTime.tryParse(
            (json['updated_at'] ?? json['updatedAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      unlockedAt: DateTime.tryParse(
        (json['unlocked_at'] ?? json['unlockedAt'])?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'collected_fragments': collectedFragments,
    'required_fragments': requiredFragments,
    'updated_at': updatedAt.toIso8601String(),
    'unlocked_at': unlockedAt?.toIso8601String(),
  };

  CosmeticFragmentProgress copyWith({
    int? collectedFragments,
    int? requiredFragments,
    DateTime? updatedAt,
    DateTime? unlockedAt,
  }) {
    return CosmeticFragmentProgress(
      itemId: itemId,
      collectedFragments: collectedFragments ?? this.collectedFragments,
      requiredFragments: requiredFragments ?? this.requiredFragments,
      updatedAt: updatedAt ?? this.updatedAt,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class DailyRunCosmeticGrantResult {
  const DailyRunCosmeticGrantResult({
    required this.item,
    required this.progress,
    required this.previousFragments,
    required this.didUnlock,
    this.unlockedCosmetic,
  });

  final CosmeticItem item;
  final CosmeticFragmentProgress progress;
  final int previousFragments;
  final bool didUnlock;
  final UserCosmetic? unlockedCosmetic;
}
