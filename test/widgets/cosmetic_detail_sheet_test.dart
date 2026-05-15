import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/models/cosmetic_fragment_progress.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/state/avatar_provider.dart';
import 'package:mathlearning/state/cosmetic_preview_provider.dart';
import 'package:mathlearning/state/cosmetic_target_provider.dart';
import 'package:mathlearning/widgets/cosmetic_detail_sheet.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CTA shows remaining fragments for current user progress', (
    tester,
  ) async {
    final now = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: CosmeticDetailSheet(
                loadout: const SocialCosmeticLoadout(
                  avatarFrameId: 'frame_comet',
                ),
                item: const SocialCosmeticFlexItem(
                  itemId: 'frame_comet',
                  name: 'Comet Frame',
                  rarity: CosmeticRarity.rare,
                  slotLabel: 'Frame',
                  hasActualName: true,
                ),
                isCurrentUser: true,
                navigationContext: context,
                progressLoader: (_) async => CosmeticFragmentProgress(
                  itemId: 'frame_comet',
                  collectedFragments: 3,
                  requiredFragments: 5,
                  updatedAt: now,
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comet Frame'), findsOneWidget);
    expect(find.text('Daily chests can drop this fragment.'), findsOneWidget);
    expect(find.text('Fragment progress: 3 / 5'), findsOneWidget);
    expect(find.text('Start Daily Run — 2 more to unlock'), findsOneWidget);
  });

  testWidgets('CTA uses short one-more copy', (tester) async {
    final now = DateTime(2026);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: CosmeticDetailSheet(
                loadout: const SocialCosmeticLoadout(trailId: 'trail_nova'),
                item: const SocialCosmeticFlexItem(
                  itemId: 'trail_nova',
                  name: 'Nova Trail',
                  rarity: CosmeticRarity.epic,
                  slotLabel: 'Trail',
                  hasActualName: true,
                ),
                isCurrentUser: true,
                navigationContext: context,
                progressLoader: (_) async => CosmeticFragmentProgress(
                  itemId: 'trail_nova',
                  collectedFragments: 4,
                  requiredFragments: 5,
                  updatedAt: now,
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start Daily Run — 1 more!'), findsOneWidget);
  });

  testWidgets('Set as target CTA persists target and shows success state', (
    tester,
  ) async {
    final provider = CosmeticTargetProvider();
    await provider.load(userId: 'user-1');

    await tester.pumpWidget(
      ChangeNotifierProvider<CosmeticTargetProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: CosmeticDetailSheet(
                  loadout: const SocialCosmeticLoadout(
                    avatarFrameId: 'frame_comet',
                  ),
                  item: const SocialCosmeticFlexItem(
                    itemId: 'frame_comet',
                    name: 'Comet Frame',
                    rarity: CosmeticRarity.rare,
                    slotLabel: 'Frame',
                    hasActualName: true,
                  ),
                  isCurrentUser: false,
                  navigationContext: context,
                  progressLoader: (_) async => CosmeticFragmentProgress(
                    itemId: 'frame_comet',
                    collectedFragments: 2,
                    requiredFragments: 5,
                    updatedAt: DateTime(2026),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set as target'), findsOneWidget);
    await tester.tap(find.byKey(const Key('set_cosmetic_target_button')));
    await tester.pumpAndSettle();

    expect(provider.target?.targetCosmeticItemId, 'frame_comet');
    expect(provider.target?.targetFragmentsOwned, 2);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == 'Target set' || widget.data == 'Current target'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('detail sheet labels already targeted item as current target', (
    tester,
  ) async {
    final provider = CosmeticTargetProvider();
    await provider.load(userId: 'user-1');
    await provider.setTargetFromFlexItem(
      item: const SocialCosmeticFlexItem(
        itemId: 'frame_comet',
        name: 'Comet Frame',
        rarity: CosmeticRarity.rare,
        slotLabel: 'Frame',
        hasActualName: true,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<CosmeticTargetProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: CosmeticDetailSheet(
                  loadout: const SocialCosmeticLoadout(
                    avatarFrameId: 'frame_comet',
                  ),
                  item: const SocialCosmeticFlexItem(
                    itemId: 'frame_comet',
                    name: 'Comet Frame',
                    rarity: CosmeticRarity.rare,
                    slotLabel: 'Frame',
                    hasActualName: true,
                  ),
                  isCurrentUser: false,
                  navigationContext: context,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current target'), findsOneWidget);
  });

  testWidgets('Try the look opens preview panel from cosmetic detail sheet', (
    tester,
  ) async {
    final avatarProvider = AvatarProvider();
    final previewProvider = CosmeticPreviewProvider()..configureUser('user-1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AvatarProvider>.value(value: avatarProvider),
          ChangeNotifierProvider<CosmeticPreviewProvider>.value(
            value: previewProvider,
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: CosmeticDetailSheet(
                  loadout: const SocialCosmeticLoadout(
                    avatarFrameId: 'frame_comet',
                  ),
                  item: const SocialCosmeticFlexItem(
                    itemId: 'frame_comet',
                    name: 'Comet Frame',
                    rarity: CosmeticRarity.rare,
                    slotLabel: 'Frame',
                    hasActualName: true,
                  ),
                  isCurrentUser: true,
                  navigationContext: context,
                  progressLoader: (_) async => CosmeticFragmentProgress(
                    itemId: 'frame_comet',
                    collectedFragments: 2,
                    requiredFragments: 5,
                    updatedAt: DateTime(2026),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detail_try_on_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('detail_try_on_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('cosmetic_try_on_panel')), findsOneWidget);
    expect(find.byKey(const Key('previewing_pill')), findsOneWidget);
    expect(find.byKey(const Key('back_to_my_look_button')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('back_to_my_look_button')));
    await tester.tap(find.byKey(const Key('back_to_my_look_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('cosmetic_try_on_panel')), findsNothing);
  });
}
