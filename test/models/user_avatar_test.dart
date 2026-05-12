import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/models/user_avatar.dart';

void main() {
  group('UserAvatar round-trip', () {
    test('animatedEffectId is preserved through toJson/fromJson', () {
      final original = UserAvatar.defaults('user_1').copyWith(
        animatedEffectId: 'effect_nova_trail',
      );
      final restored = UserAvatar.fromJson(original.toJson());
      expect(restored.animatedEffectId, equals('effect_nova_trail'));
    });

    test('frameId is preserved through toJson/fromJson', () {
      final original = UserAvatar.defaults('user_1').copyWith(
        frameId: 'frame_comet',
      );
      final restored = UserAvatar.fromJson(original.toJson());
      expect(restored.frameId, equals('frame_comet'));
    });

    test('accessoryId is preserved through toJson/fromJson', () {
      final original = UserAvatar.defaults('user_1').copyWith(
        accessoryId: 'acc_math_crown',
      );
      final restored = UserAvatar.fromJson(original.toJson());
      expect(restored.accessoryId, equals('acc_math_crown'));
    });

    test('fromJson accepts snake_case animated_effect_id', () {
      final avatar = UserAvatar.fromJson({
        'userId': 'u1',
        'animated_effect_id': 'effect_comet_tail',
      });
      expect(avatar.animatedEffectId, equals('effect_comet_tail'));
    });

    test('fromJson accepts camelCase animatedEffectId', () {
      final avatar = UserAvatar.fromJson({
        'userId': 'u1',
        'animatedEffectId': 'effect_comet_tail',
      });
      expect(avatar.animatedEffectId, equals('effect_comet_tail'));
    });
  });
}
