import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';

void main() {
  group('SocialCosmeticLoadout.equippedItemLabels', () {
    test('returns empty list when nothing equipped', () {
      const loadout = SocialCosmeticLoadout();
      expect(loadout.equippedItemLabels, isEmpty);
    });

    test('derives friendly name from avatarFrameId when not in recentUnlocks', () {
      const loadout = SocialCosmeticLoadout(
        avatarFrameId: 'frame_comet',
      );
      final labels = loadout.equippedItemLabels;
      expect(labels.length, 1);
      expect(labels.first.name, equals('Comet'));
    });

    test('prefers name from recentUnlocks when item matches', () {
      const loadout = SocialCosmeticLoadout(
        avatarFrameId: 'frame_comet',
        recentUnlocks: [
          SocialCosmeticUnlock(
            itemId: 'frame_comet',
            name: 'Comet Frame',
            rarity: CosmeticRarity.rare,
          ),
        ],
      );
      final labels = loadout.equippedItemLabels;
      expect(labels.length, 1);
      expect(labels.first.name, equals('Comet Frame'));
      expect(labels.first.rarity, equals(CosmeticRarity.rare));
    });

    test('returns labels for all three slots when all equipped', () {
      const loadout = SocialCosmeticLoadout(
        avatarFrameId: 'frame_comet',
        animatedEffectId: 'effect_nova_trail',
        accessoryId: 'acc_math_crown',
      );
      final labels = loadout.equippedItemLabels;
      expect(labels.length, 3);
      expect(labels.map((l) => l.name), containsAll(['Comet', 'Nova Trail', 'Math Crown']));
    });

    test('rarity is null when slot not in recentUnlocks', () {
      const loadout = SocialCosmeticLoadout(
        avatarFrameId: 'frame_comet',
      );
      expect(loadout.equippedItemLabels.first.rarity, isNull);
    });
  });
}
