import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/state/daily_run_provider.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'Daily Run chest transaction resumes after restart without duplicate reward application',
    () async {
      final provider = DailyRunProvider();
      await provider.load('user-1');
      await provider.markCompleted();

      final reward = await provider.openChest();
      final transactionId = provider.activeRewardTransactionId;
      expect(reward, isNotNull);
      expect(transactionId, isNotNull);

      await provider.markRewardTransactionStarted(
        expectedTransactionId: transactionId,
      );

      var xpCalls = 0;
      var coinCalls = 0;
      var fragmentCalls = 0;
      var targetCalls = 0;
      var seasonCalls = 0;
      var dailyReturnCalls = 0;

      await provider.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.xp,
        action: () async {
          xpCalls += 1;
        },
      );
      await provider.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.coins,
        action: () async {
          coinCalls += 1;
        },
      );

      final restarted = DailyRunProvider();
      await restarted.load('user-1');

      expect(restarted.activeRewardTransactionId, transactionId);
      expect(restarted.chestOpeningInProgress, isTrue);
      expect(restarted.isRewardStepApplied(DailyChestRewardStep.xp), isTrue);
      expect(restarted.isRewardStepApplied(DailyChestRewardStep.coins), isTrue);
      expect(
        restarted.activeRewardTransactionReward?.xp,
        reward!.xp,
      );

      await restarted.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.xp,
        action: () async {
          xpCalls += 1;
        },
      );
      await restarted.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.coins,
        action: () async {
          coinCalls += 1;
        },
      );
      await restarted.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.cosmeticFragments,
        action: () async {
          fragmentCalls += 1;
        },
      );
      await restarted.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.targetChaseProgress,
        action: () async {
          targetCalls += 1;
        },
      );
      await restarted.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.seasonRewards,
        action: () async {
          seasonCalls += 1;
        },
      );
      await restarted.applyRewardStep(
        expectedTransactionId: transactionId,
        step: DailyChestRewardStep.dailyReturnRewards,
        action: () async {
          dailyReturnCalls += 1;
        },
      );

      expect(xpCalls, 1);
      expect(coinCalls, 1);
      expect(fragmentCalls, 1);
      expect(targetCalls, 1);
      expect(seasonCalls, 1);
      expect(dailyReturnCalls, 1);
      expect(restarted.rewardsApplied, isTrue);

      await restarted.markChestPermanentlyOpened(
        expectedTransactionId: transactionId,
      );
      expect(restarted.chestPermanentlyOpened, isTrue);
      expect(await restarted.openChest(), isNull);
    },
  );
}
