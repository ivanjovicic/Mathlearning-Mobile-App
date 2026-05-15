import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';

void main() {
  group('SocialCosmeticLoadout.equippedItemLabels', () {
    test('returns empty list when nothing equipped', () {
      const loadout = SocialCosmeticLoadout();
      expect(loadout.equippedItemLabels, isEmpty);
    });

    test(
      'derives friendly name from avatarFrameId when not in recentRareUnlocks',
      () {
        const loadout = SocialCosmeticLoadout(avatarFrameId: 'frame_comet');
        final labels = loadout.equippedItemLabels;
        expect(labels.length, 1);
        expect(labels.first.name, equals('Comet'));
      },
    );

    test('prefers name from recentRareUnlocks when item matches', () {
      const loadout = SocialCosmeticLoadout(
        avatarFrameId: 'frame_comet',
        recentRareUnlocks: [
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
        trailId: 'trail_nova',
        avatarGearId: 'gear_math_crown',
        answerEffectId: 'effect_neon_number_burst',
        profileBackgroundId: 'bg_starfield',
      );
      final labels = loadout.equippedItemLabels;
      expect(labels.length, 5);
      expect(
        labels.map((l) => l.name),
        containsAll([
          'Comet',
          'Nova',
          'Math Crown',
          'Neon Number Burst',
          'Starfield',
        ]),
      );
    });

    test('rarity is null when slot not in recentRareUnlocks', () {
      const loadout = SocialCosmeticLoadout(avatarFrameId: 'frame_comet');
      expect(loadout.equippedItemLabels.first.rarity, isNull);
    });

    test('fromJson keeps null API loadout as clean default', () {
      final loadout = SocialCosmeticLoadout.fromJson({
        'avatarFrameId': null,
        'trailId': null,
        'avatarGearId': null,
        'answerEffectId': null,
        'profileBackgroundId': null,
        'recentRareUnlocks': const <dynamic>[],
      });

      expect(loadout.hasEquippedCosmetics, isFalse);
      expect(loadout.recentRareUnlocks, isEmpty);
      expect(loadout.isEmpty, isTrue);
    });

    test('flexItem chooses frame over higher-rarity background', () {
      const loadout = SocialCosmeticLoadout(
        avatarFrameId: 'frame_comet',
        profileBackgroundId: 'bg_mythic_nebula',
        recentRareUnlocks: [
          SocialCosmeticUnlock(
            itemId: 'frame_comet',
            name: 'Comet Frame',
            rarity: CosmeticRarity.rare,
          ),
          SocialCosmeticUnlock(
            itemId: 'bg_mythic_nebula',
            name: 'Mythic Nebula',
            rarity: CosmeticRarity.mythic,
          ),
        ],
      );

      expect(loadout.flexItem?.itemId, equals('frame_comet'));
      expect(loadout.flexItem?.name, equals('Comet Frame'));
    });

    test('flexItem fallback label uses slot type instead of style', () {
      const loadout = SocialCosmeticLoadout(
        trailId: 'trail_unknown_epic',
        highlightRarity: CosmeticRarity.epic,
      );

      expect(loadout.flexItem?.name, equals('Epic Trail'));
    });
  });
}
