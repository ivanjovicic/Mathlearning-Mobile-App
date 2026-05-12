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
          'frame_id': 'frame_comet',
          'animated_effect_id': 'effect_nova_trail',
        },
      });
      expect(item.cosmeticLoadout, isNotNull);
      expect(item.cosmeticLoadout!.avatarFrameId, equals('frame_comet'));
      expect(item.cosmeticLoadout!.animatedEffectId, equals('effect_nova_trail'));
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
  });
}
