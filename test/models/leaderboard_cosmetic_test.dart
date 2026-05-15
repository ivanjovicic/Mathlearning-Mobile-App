import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/leaderboard_models.dart';

void main() {
  group('LeaderboardItem.fromJson cosmeticLoadout', () {
    test('cosmeticLoadout is null when field absent from API response', () {
      final item = LeaderboardItem.fromJson({
        'rank': 1,
        'userId': 1,
        'displayName': 'Alice',
        'score': 100,
        'streakDays': 0,
      });
      expect(item.cosmeticLoadout, isNull);
    });

    test('cosmeticLoadout is parsed when cosmeticLoadout field present', () {
      final item = LeaderboardItem.fromJson({
        'rank': 2,
        'userId': 2,
        'displayName': 'Bob',
        'score': 90,
        'streakDays': 5,
        'cosmeticLoadout': {
          'avatarFrameId': 'frame_comet',
          'trailId': 'trail_nova',
          'avatarGearId': 'gear_math_crown',
          'answerEffectId': 'effect_neon_number_burst',
          'profileBackgroundId': 'bg_starfield',
          'recentRareUnlocks': [
            {'itemId': 'frame_comet', 'name': 'Comet Frame', 'rarity': 'rare'},
          ],
        },
      });
      expect(item.cosmeticLoadout, isNotNull);
      expect(item.cosmeticLoadout!.avatarFrameId, equals('frame_comet'));
      expect(item.cosmeticLoadout!.trailId, equals('trail_nova'));
      expect(item.cosmeticLoadout!.avatarGearId, equals('gear_math_crown'));
      expect(
        item.cosmeticLoadout!.answerEffectId,
        equals('effect_neon_number_burst'),
      );
      expect(item.cosmeticLoadout!.profileBackgroundId, equals('bg_starfield'));
      expect(
        item.cosmeticLoadout!.recentRareUnlocks.single.name,
        'Comet Frame',
      );
    });

    test('cosmeticLoadout is parsed when cosmetics field present', () {
      final item = LeaderboardItem.fromJson({
        'rank': 3,
        'userId': 3,
        'displayName': 'Carol',
        'score': 80,
        'streakDays': 2,
        'cosmetics': {'frame_id': 'frame_gold_laurel'},
      });
      expect(item.cosmeticLoadout, isNotNull);
      expect(item.cosmeticLoadout!.avatarFrameId, equals('frame_gold_laurel'));
    });

    test('cosmeticLoadout is parsed from top-level optional API fields', () {
      final item = LeaderboardItem.fromJson({
        'rank': 4,
        'userId': 4,
        'displayName': 'Dana',
        'score': 70,
        'streakDays': 1,
        'avatarFrameId': 'frame_comet',
        'trailId': 'trail_nova',
        'recentRareUnlocks': const <Map<String, dynamic>>[],
      });
      expect(item.cosmeticLoadout, isNotNull);
      expect(item.cosmeticLoadout!.avatarFrameId, equals('frame_comet'));
      expect(item.cosmeticLoadout!.trailId, equals('trail_nova'));
      expect(item.cosmeticLoadout!.recentRareUnlocks, isEmpty);
    });
  });
}
