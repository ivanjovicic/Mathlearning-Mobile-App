import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/cosmetic_target.dart';
import 'package:mathlearning/widgets/target_cosmetic_chase_card.dart';

void main() {
  testWidgets('Daily Run header updates with target cosmetic progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TargetCosmeticChaseCard(
            target: CosmeticTarget(
              targetCosmeticItemId: 'frame_comet',
              targetFragmentsOwned: 3,
              targetFragmentsRequired: 5,
              targetRarity: CosmeticRarity.rare,
              targetItemName: 'Comet Frame',
              targetSlotLabel: 'Frame',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_run_target_header')), findsOneWidget);
    expect(find.text('Comet Frame'), findsOneWidget);
    expect(find.text('3/5 fragments'), findsOneWidget);
    expect(find.text('Rare'), findsOneWidget);
  });

  testWidgets('Daily Run header calls out one remaining fragment', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TargetCosmeticChaseCard(
            target: CosmeticTarget(
              targetCosmeticItemId: 'frame_comet',
              targetFragmentsOwned: 4,
              targetFragmentsRequired: 5,
              targetRarity: CosmeticRarity.rare,
              targetItemName: 'Comet Frame',
              targetSlotLabel: 'Frame',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 more fragment!'), findsOneWidget);
  });

  testWidgets('shows no-target prompt when target is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TargetCosmeticChaseCard(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('no_target_prompt')), findsOneWidget);
    expect(find.text('Pick your next chase'), findsOneWidget);
    expect(find.byKey(const Key('daily_run_target_header')), findsNothing);
  });

  testWidgets('bonus progress pips appear when bonusProgress is set', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TargetCosmeticChaseCard(
            target: CosmeticTarget(
              targetCosmeticItemId: 'frame_comet',
              targetFragmentsOwned: 2,
              targetFragmentsRequired: 5,
              targetRarity: CosmeticRarity.rare,
              targetItemName: 'Comet Frame',
              targetSlotLabel: 'Frame',
              bonusProgress: 2,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 5 pips rendered via ValueKey('pip_0') ... ValueKey('pip_4')
    expect(find.byKey(const ValueKey('pip_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('pip_4')), findsOneWidget);
    // Display shows X/5 text
    expect(
      find.text('2/${CosmeticTarget.kBonusProgressMax}'),
      findsOneWidget,
    );
  });
}
