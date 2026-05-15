import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/models/user_avatar.dart';
import 'package:mathlearning/state/cosmetic_preview_provider.dart';

void main() {
  group('CosmeticPreviewProvider', () {
    test('preview applies locally to avatar and loadout', () {
      final provider = CosmeticPreviewProvider()..configureUser('me');
      const item = SocialCosmeticFlexItem(
        itemId: 'frame_comet',
        name: 'Comet Frame',
        rarity: CosmeticRarity.rare,
        slotLabel: 'Frame',
        hasActualName: true,
      );

      provider.startPreview(item);

      final avatar = provider.applyToAvatar(UserAvatar.defaults('me'));
      final loadout = provider.applyToLoadout(const SocialCosmeticLoadout());

      expect(avatar.frameId, 'frame_comet');
      expect(loadout.avatarFrameId, 'frame_comet');
      expect(loadout.highlightRarity, CosmeticRarity.rare);
    });

    test('preview restores correctly when cleared', () {
      final provider = CosmeticPreviewProvider()..configureUser('me');
      const item = SocialCosmeticFlexItem(
        itemId: 'effect_neon_number_burst',
        name: 'Neon Number Burst',
        rarity: CosmeticRarity.epic,
        slotLabel: 'Effect',
        hasActualName: true,
      );
      final baseAvatar = UserAvatar.defaults('me');
      const baseLoadout = SocialCosmeticLoadout();

      provider.startPreview(item);
      provider.clearPreview();

      final avatar = provider.applyToAvatar(baseAvatar);
      final loadout = provider.applyToLoadout(baseLoadout);

      expect(avatar.animatedEffectId, baseAvatar.animatedEffectId);
      expect(loadout.answerEffectId, isNull);
      expect(provider.isPreviewing, isFalse);
    });

    test('preview does not persist after restart', () {
      final first = CosmeticPreviewProvider()..configureUser('me');
      first.startPreview(
        const SocialCosmeticFlexItem(
          itemId: 'bg_galaxy',
          name: 'Galaxy Background',
          rarity: CosmeticRarity.legendary,
          slotLabel: 'Background',
          hasActualName: true,
        ),
      );
      expect(first.isPreviewing, isTrue);

      final restarted = CosmeticPreviewProvider()..configureUser('me');
      expect(restarted.isPreviewing, isFalse);
      expect(restarted.previewItem, isNull);
    });
  });
}