import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/state/daily_run_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> applyAllRewardSteps(
    DailyRunProvider provider, {
    required String transactionId,
  }) async {
    await provider.applyRewardStep(
      expectedTransactionId: transactionId,
      step: DailyChestRewardStep.xp,
      action: () async {},
    );
    await provider.applyRewardStep(
      expectedTransactionId: transactionId,
      step: DailyChestRewardStep.coins,
      action: () async {},
    );
    await provider.applyRewardStep(
      expectedTransactionId: transactionId,
      step: DailyChestRewardStep.cosmeticFragments,
      action: () async {},
    );
    await provider.applyRewardStep(
      expectedTransactionId: transactionId,
      step: DailyChestRewardStep.targetChaseProgress,
      action: () async {},
    );
    await provider.applyRewardStep(
      expectedTransactionId: transactionId,
      step: DailyChestRewardStep.seasonRewards,
      action: () async {},
    );
    await provider.applyRewardStep(
      expectedTransactionId: transactionId,
      step: DailyChestRewardStep.dailyReturnRewards,
      action: () async {},
    );
  }

  test(
    'crash/restart before rewards applied keeps resumable transaction',
    () async {
      final provider = DailyRunProvider();
      await provider.load('user-1');
      await provider.markCompleted();

      final openedReward = await provider.openChest();
      final transactionId = provider.activeRewardTransactionId;
      expect(openedReward, isNotNull);
      expect(transactionId, isNotNull);
      expect(provider.chestPermanentlyOpened, isFalse);
      expect(provider.chestState, DailyChestState.ready);

      await provider.markRewardTransactionStarted(
        expectedTransactionId: transactionId,
      );
      await provider.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.xp,
        action: () async {},
      );

      final restarted = DailyRunProvider();
      await restarted.load('user-1');

      expect(restarted.chestPermanentlyOpened, isFalse);
      expect(restarted.chestState, DailyChestState.ready);
      expect(restarted.activeRewardTransactionId, transactionId);
      expect(restarted.isRewardStepApplied(DailyChestRewardStep.xp), isTrue);

      final resumedReward = await restarted.openChest();
      expect(resumedReward, isNotNull);
      expect(resumedReward!.xp, openedReward!.xp);
      expect(resumedReward.coins, openedReward.coins);
      expect(resumedReward.cosmeticFragment, openedReward.cosmeticFragment);
    },
  );

  test(
    'chest is not permanently opened until all rewards are applied',
    () async {
      final provider = DailyRunProvider();
      await provider.load('user-1');
      await provider.markCompleted();
      await provider.openChest();
      final transactionId = provider.activeRewardTransactionId;
      expect(transactionId, isNotNull);

      await provider.markRewardTransactionStarted(
        expectedTransactionId: transactionId,
      );
      await provider.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.xp,
        action: () async {},
      );
      await provider.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.coins,
        action: () async {},
      );

      expect(
        () => provider.markChestPermanentlyOpened(
          expectedTransactionId: transactionId,
        ),
        throwsStateError,
      );
      expect(provider.chestPermanentlyOpened, isFalse);
      expect(provider.chestState, DailyChestState.ready);

      await applyAllRewardSteps(provider, transactionId: transactionId!);
      expect(provider.rewardsApplied, isTrue);

      await provider.markChestPermanentlyOpened(
        expectedTransactionId: transactionId,
      );
      expect(provider.chestPermanentlyOpened, isTrue);
      expect(provider.chestState, DailyChestState.opened);
    },
  );

  test(
    'duplicate claim is prevented while pending and after completion',
    () async {
      final provider = DailyRunProvider();
      await provider.load('user-1');
      await provider.markCompleted();

      final firstReward = await provider.openChest();
      final firstTransactionId = provider.activeRewardTransactionId;
      expect(firstReward, isNotNull);
      expect(firstTransactionId, isNotNull);

      final secondReward = await provider.openChest();
      expect(secondReward, isNotNull);
      expect(provider.activeRewardTransactionId, firstTransactionId);
      expect(secondReward!.xp, firstReward!.xp);
      expect(secondReward.coins, firstReward.coins);

      await provider.markRewardTransactionStarted(
        expectedTransactionId: firstTransactionId,
      );
      await applyAllRewardSteps(provider, transactionId: firstTransactionId!);
      await provider.markChestPermanentlyOpened(
        expectedTransactionId: firstTransactionId,
      );

      final afterOpen = await provider.openChest();
      expect(afterOpen, isNull);
      expect(provider.chestState, DailyChestState.opened);
    },
  );

  test('retry after partial failure works safely', () async {
    final provider = DailyRunProvider();
    await provider.load('user-1');
    await provider.markCompleted();
    await provider.openChest();
    final transactionId = provider.activeRewardTransactionId;
    expect(transactionId, isNotNull);

    await provider.markRewardTransactionStarted(
      expectedTransactionId: transactionId,
    );

    var attempts = 0;
    await expectLater(
      provider.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.xp,
        action: () async {
          attempts += 1;
          if (attempts == 1) {
            throw Exception('temporary failure');
          }
        },
      ),
      throwsException,
    );
    expect(provider.isRewardStepApplied(DailyChestRewardStep.xp), isFalse);

    await provider.applyRewardStep(
      expectedTransactionId: transactionId,
      step: DailyChestRewardStep.xp,
      action: () async {
        attempts += 1;
      },
    );
    expect(provider.isRewardStepApplied(DailyChestRewardStep.xp), isTrue);
    expect(attempts, 2);
  });

  test(
    'corrupted pending transaction rolls back to safe ready state',
    () async {
      final provider = DailyRunProvider();
      await provider.load('user-2');
      await provider.markCompleted();

      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final key = 'daily_run.state.v1.user-2.${now.year}-$month-$day';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        key,
        jsonEncode({
          'isCompleted': true,
          'activeRewardTransactionId': 'broken_tx',
          'chestOpeningInProgress': true,
          'rewardsApplied': false,
          // intentionally missing activeRewardTransactionReward payload
        }),
      );

      final restarted = DailyRunProvider();
      await restarted.load('user-2');

      expect(restarted.chestState, DailyChestState.ready);
      expect(restarted.activeRewardTransactionId, isNull);
      expect(restarted.chestOpeningInProgress, isFalse);
      expect(restarted.chestPermanentlyOpened, isFalse);
    },
  );
}
