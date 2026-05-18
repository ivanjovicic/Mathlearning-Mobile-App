import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_recommendation.dart';
import 'package:mathlearning/features/learning_map/models/skill_mastery.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/features/learning_map/screens/learning_map_screen.dart';
import 'package:mathlearning/features/learning_map/services/learning_map_service.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_chest.dart';
import 'package:mathlearning/features/learning_map/widgets/daily_chest_reward_sheet.dart';
import 'package:mathlearning/models/cosmetic_item.dart';
import 'package:mathlearning/models/hint_models.dart';
import 'package:mathlearning/models/user_avatar.dart';
import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/services/cosmetics_service.dart';
import 'package:mathlearning/services/daily_run_api_service.dart';
import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/avatar_provider.dart';
import 'package:mathlearning/state/coin_provider.dart';
import 'package:mathlearning/state/daily_return_provider.dart';
import 'package:mathlearning/state/daily_run_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/settings_provider.dart';
import 'package:mathlearning/state/streak_freeze_provider.dart';

import '../../helpers/test_fakes.dart';

class _FakeLearningMapSource implements LearningMapDataSource {
  @override
  Future<ApiResult<AdaptiveLearningPath>> fetchPath(String userId) async {
    return ApiResult(
      data: AdaptiveLearningPath.fromJson({
        'nodes': [
          {
            'id': 'n1',
            'title': 'Fractions Basics',
            'topicId': 4,
            'subtopicId': 12,
            'mastery': 0.32,
            'isLocked': false,
            'recommendedDifficulty': 'easy',
          },
        ],
        'edges': const [],
        'recommendedNext': 'n1',
        'generatedAt': '2026-03-05T10:00:00Z',
      }),
    );
  }

  @override
  Future<ApiResult<List<SkillMastery>>> fetchMastery(String userId) async {
    return ApiResult(
      data: const [
        SkillMastery(
          topicId: 4,
          topicName: 'Fractions',
          masteryProbability: 0.41,
        ),
      ],
    );
  }

  @override
  Future<ApiResult<List<PracticeRecommendation>>> fetchRecommendations(
    String userId,
  ) async {
    return ApiResult(
      data: const [
        PracticeRecommendation(
          topicId: 4,
          topicName: 'Fractions',
          reason: 'low_mastery',
          priorityScore: 0.9,
          recommendedDifficulty: SkillDifficulty.medium,
          practiceId: 'fractions_pack_1',
        ),
      ],
    );
  }

  @override
  Future<ApiResult<List<SkillMastery>>> fetchWeakness(String userId) async {
    return ApiResult(
      data: const [
        SkillMastery(
          topicId: 4,
          topicName: 'Fractions',
          masteryProbability: 0.3,
        ),
      ],
    );
  }
}

class _SuccessfulProgressProvider extends ProgressProvider {
  _SuccessfulProgressProvider()
    : super(fetchProgressOverview: _fakeOverview, enableDemoFallback: true);

  int loadProgressCalls = 0;

  static Future<ApiResult<Map<String, dynamic>>> _fakeOverview() async {
    return ApiResult(
      data: <String, dynamic>{
        'level': 1,
        'xp': 0,
        'streak': 0,
        'accuracy': 100.0,
        'totalAttempts': 1,
      },
    );
  }

  @override
  Future<void> loadProgress({bool forceRefresh = false}) async {
    loadProgressCalls += 1;
  }

  @override
  bool get lastProgressLoadUsedFallback => false;

  @override
  Object? get lastProgressLoadError => null;
}

class _SuccessfulAvatarProvider extends AvatarProvider {
  _SuccessfulAvatarProvider() {
    _catalog = CosmeticsService.instance.getCatalog();
    _avatarConfig = UserAvatar.defaults('user-1');
  }

  int loadCalls = 0;
  late final List<CosmeticItem> _catalog;
  UserAvatar? _avatarConfig;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  UserAvatar? get avatarConfig => _avatarConfig;

  @override
  List<CosmeticItem> get catalog => List.unmodifiable(_catalog);

  @override
  Future<void> load() async {
    loadCalls += 1;
    _avatarConfig ??= UserAvatar.defaults('user-1');
  }
}

class _SuccessfulCoinProvider extends TestCoinProvider {
  _SuccessfulCoinProvider({required super.coins, required super.dailyHints});

  int loadCalls = 0;

  @override
  Future<void> loadCoinsAndHints({bool forceRefresh = false}) async {
    loadCalls += 1;
  }
}

class _EnglishSettingsProvider extends SettingsProvider {
  @override
  AppLanguage get language => AppLanguage.english;
}

String _apiDay(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _SuccessfulDailyRunApiService extends DailyRunApiService {
  _SuccessfulDailyRunApiService(this._rewardProvider) : super(dio: Dio());

  final DailyChestReward? Function() _rewardProvider;

  int claimCalls = 0;
  String? claimedTransactionId;
  String? claimedDate;

  @override
  Future<DailyRunChestClaimResponse?> claimChest({
    required String transactionId,
    required DateTime date,
  }) async {
    claimCalls += 1;
    claimedTransactionId = transactionId;
    claimedDate = _apiDay(date);

    final reward = _rewardProvider();
    if (reward == null) {
      return null;
    }

    return DailyRunChestClaimResponse(
      success: true,
      date: claimedDate!,
      transactionId: transactionId,
      alreadyClaimed: false,
      reward: DailyRunChestClaimReward(
        xp: reward.xp,
        coins: reward.coins,
        cosmeticFragment: reward.cosmeticFragment,
        fragmentCopies: reward.fragmentCopies,
      ),
      balances: DailyRunChestClaimBalances(
        xp: reward.xp,
        level: 1,
        coins: reward.coins,
      ),
    );
  }
}

Future<T> _withTimeout<T>(Future<T> future, String step) {
  return future.timeout(
    const Duration(seconds: 5),
    onTimeout: () => throw TimeoutException('Timed out during $step'),
  );
}

Widget _buildTestShell({
  required LearningMapProvider learningMapProvider,
  required DailyRunProvider dailyRunProvider,
  required DailyRunApiService dailyRunApiService,
  required ProgressProvider progressProvider,
  required CoinProvider coinProvider,
  required AvatarProvider avatarProvider,
  required StreakFreezeProvider streakFreezeProvider,
  required DailyReturnProvider dailyReturnProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => TestAuthProvider()),
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => _EnglishSettingsProvider(),
      ),
      ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider),
      ChangeNotifierProvider<CoinProvider>.value(value: coinProvider),
      ChangeNotifierProvider<AvatarProvider>.value(value: avatarProvider),
      ChangeNotifierProvider<DailyRunProvider>.value(value: dailyRunProvider),
      ChangeNotifierProvider<StreakFreezeProvider>.value(
        value: streakFreezeProvider,
      ),
      ChangeNotifierProvider<DailyReturnProvider>.value(
        value: dailyReturnProvider,
      ),
      ChangeNotifierProvider<LearningMapProvider>.value(
        value: learningMapProvider,
      ),
    ],
    child: MaterialApp(
      home: LearningMapScreen(
        userId: 'user-1',
        dailyRunApiService: dailyRunApiService,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'LearningMapScreen chest wiring applies all reward steps before permanent open',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1440, 1400);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      DailyChestReward? claimReward;
      final dailyRunApiService = _SuccessfulDailyRunApiService(
        () => claimReward,
      );

      final learningMapProvider = LearningMapProvider(
        service: _FakeLearningMapSource(),
      );
      await learningMapProvider.loadAll('user-1');
      final dailyRunProvider = DailyRunProvider();
      await dailyRunProvider.load('user-1');
      await dailyRunProvider.markCompleted();

      final progressProvider = _SuccessfulProgressProvider();
      final coinProvider = _SuccessfulCoinProvider(
        coins: 42,
        dailyHints: UserDailyHints(
          userId: 'user-1',
          date: DateTime(2026, 2, 6),
        ),
      );
      final avatarProvider = _SuccessfulAvatarProvider();
      final streakFreezeProvider = StreakFreezeProvider();
      final dailyReturnProvider = DailyReturnProvider();

      await tester.pumpWidget(
        _buildTestShell(
          learningMapProvider: learningMapProvider,
          dailyRunProvider: dailyRunProvider,
          dailyRunApiService: dailyRunApiService,
          progressProvider: progressProvider,
          coinProvider: coinProvider,
          avatarProvider: avatarProvider,
          streakFreezeProvider: streakFreezeProvider,
          dailyReturnProvider: dailyReturnProvider,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(DailyChest), findsOneWidget);
      expect(
        tester.widget<DailyChest>(find.byType(DailyChest)).state,
        DailyChestState.ready,
      );

      await tester.tap(find.byType(DailyChest).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(DailyChestRewardSheet), findsOneWidget);

      final sheet = tester.widget<DailyChestRewardSheet>(
        find.byType(DailyChestRewardSheet),
      );
      final transactionId = dailyRunProvider.activeRewardTransactionId;
      expect(transactionId, isNotNull);
      claimReward = sheet.reward;

      await _withTimeout(
        Future.sync(() => sheet.onMarkRewardTransactionStarted?.call()),
        'mark reward transaction started',
      );
      await _withTimeout(
        Future.sync(() => sheet.onApplyXp?.call(sheet.reward.xp)),
        'apply xp',
      );
      await _withTimeout(
        Future.sync(() => sheet.onApplyCoins?.call(sheet.reward.coins)),
        'apply coins',
      );
      final fragmentGrant = await _withTimeout(
        sheet.onGrantCosmeticFragments!(
          sheet.reward.cosmeticFragment,
          sheet.reward.fragmentCopies,
        ),
        'grant cosmetic fragments',
      );
      await _withTimeout(
        Future.sync(() => sheet.onApplyTargetProgress?.call(fragmentGrant)),
        'apply target progress',
      );

      expect(
        dailyRunProvider.isRewardStepApplied(DailyChestRewardStep.xp),
        isTrue,
      );
      expect(
        dailyRunProvider.isRewardStepApplied(DailyChestRewardStep.coins),
        isTrue,
      );
      expect(
        dailyRunProvider.isRewardStepApplied(
          DailyChestRewardStep.cosmeticFragments,
        ),
        isTrue,
      );
      expect(
        dailyRunProvider.isRewardStepApplied(
          DailyChestRewardStep.targetChaseProgress,
        ),
        isTrue,
      );
      expect(
        dailyRunProvider.isRewardStepApplied(
          DailyChestRewardStep.seasonRewards,
        ),
        isFalse,
      );
      expect(
        dailyRunProvider.isRewardStepApplied(
          DailyChestRewardStep.dailyReturnRewards,
        ),
        isFalse,
      );
      expect(dailyRunProvider.rewardsApplied, isFalse);

      await expectLater(
        dailyRunProvider.markChestPermanentlyOpened(
          expectedTransactionId: transactionId,
        ),
        throwsA(isA<StateError>()),
      );
      expect(dailyRunProvider.chestPermanentlyOpened, isFalse);

      await _withTimeout(
        Future.sync(() => sheet.onApplyPostChestRewards?.call()),
        'apply post-chest rewards',
      );

      expect(dailyRunApiService.claimCalls, 1);
      expect(dailyRunApiService.claimedTransactionId, transactionId);
      final transactionDay = dailyRunProvider.activeRewardTransactionDay;
      expect(transactionDay, isNotNull);
      expect(dailyRunApiService.claimedDate, _apiDay(transactionDay!));
      expect(dailyRunProvider.rewardsApplied, isTrue);

      final requiredSteps = DailyChestRewardStep.values;
      for (final step in requiredSteps) {
        expect(
          dailyRunProvider.isRewardStepApplied(step),
          isTrue,
          reason: 'Expected screen wiring to apply $step',
        );
      }

      await _withTimeout(
        Future.sync(() => sheet.onMarkChestPermanentlyOpened?.call()),
        'mark chest permanently opened',
      );

      expect(dailyRunProvider.chestPermanentlyOpened, isTrue);
      expect(dailyRunProvider.activeRewardTransactionId, isNull);

      sheet.onContinue();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
