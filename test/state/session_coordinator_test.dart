import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/state/auth_provider.dart';
import 'package:mathlearning/state/avatar_provider.dart';
import 'package:mathlearning/state/chase_race_provider.dart';
import 'package:mathlearning/state/cosmetic_preview_provider.dart';
import 'package:mathlearning/state/cosmetic_target_provider.dart';
import 'package:mathlearning/state/daily_return_provider.dart';
import 'package:mathlearning/state/leaderboard_provider.dart';
import 'package:mathlearning/state/player_identity_provider.dart';
import 'package:mathlearning/state/progress_provider.dart';
import 'package:mathlearning/state/quiz_provider.dart';
import 'package:mathlearning/state/season_provider.dart';
import 'package:mathlearning/state/session_coordinator.dart';
import 'package:mathlearning/state/settings_provider.dart';
import 'package:mathlearning/state/streak_freeze_provider.dart';
import 'package:mathlearning/state/user_profile_provider.dart';
import 'package:mathlearning/state/weekly_featured_provider.dart';
import 'package:mathlearning/models/cosmetic_target.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('auth context is propagated to session-scoped providers', () async {
    final auth = FakeAuthProvider(
      authenticated: true,
      token: 'token-123',
      userId: 'user-a',
      isDemoMode: true,
    );
    final harness = TestHarness();
    final coordinator = SessionCoordinator();

    await coordinator.synchronize(
      auth: auth,
      progress: harness.progress,
      quiz: harness.quiz,
      leaderboard: harness.leaderboard,
      userProfile: harness.userProfile,
      settings: harness.settings,
      avatar: harness.avatar,
      cosmeticTarget: harness.cosmeticTarget,
      cosmeticPreview: harness.cosmeticPreview,
      weeklyFeatured: harness.weeklyFeatured,
      dailyReturn: harness.dailyReturn,
      season: harness.season,
      chaseRace: harness.chaseRace,
      playerIdentity: harness.playerIdentity,
      streakFreeze: harness.streakFreeze,
    );

    expect(harness.progress.recordedToken, 'token-123');
    expect(harness.progress.recordedUserId, 'user-a');
    expect(harness.progress.recordedIsDemoMode, isTrue);
    expect(harness.quiz.recordedToken, 'token-123');
    expect(harness.quiz.recordedIsDemoMode, isTrue);
    expect(harness.leaderboard.recordedToken, 'token-123');
    expect(harness.leaderboard.recordedIsDemoMode, isTrue);
  });

  test('logout clears in-memory user-scoped providers', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pending_answers',
      jsonEncode([
        {
          'quiz_id': 'quiz-1',
          'question_id': 11,
          'answer': '2',
          'time_spent_seconds': 5,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'is_correct': 1,
          'user_id': 'user-a',
        },
      ]),
    );

    final auth = FakeAuthProvider(
      authenticated: true,
      token: 'token-123',
      userId: 'user-a',
      isDemoMode: false,
    );
    final harness = TestHarness();
    final coordinator = SessionCoordinator();

    await coordinator.synchronize(
      auth: auth,
      progress: harness.progress,
      quiz: harness.quiz,
      leaderboard: harness.leaderboard,
      userProfile: harness.userProfile,
      settings: harness.settings,
      avatar: harness.avatar,
      cosmeticTarget: harness.cosmeticTarget,
      cosmeticPreview: harness.cosmeticPreview,
      weeklyFeatured: harness.weeklyFeatured,
      dailyReturn: harness.dailyReturn,
      season: harness.season,
      chaseRace: harness.chaseRace,
      playerIdentity: harness.playerIdentity,
      streakFreeze: harness.streakFreeze,
    );

    auth.setSession(
      authenticated: false,
      token: null,
      userId: null,
      isDemoMode: false,
    );

    await coordinator.synchronize(
      auth: auth,
      progress: harness.progress,
      quiz: harness.quiz,
      leaderboard: harness.leaderboard,
      userProfile: harness.userProfile,
      settings: harness.settings,
      avatar: harness.avatar,
      cosmeticTarget: harness.cosmeticTarget,
      cosmeticPreview: harness.cosmeticPreview,
      weeklyFeatured: harness.weeklyFeatured,
      dailyReturn: harness.dailyReturn,
      season: harness.season,
      chaseRace: harness.chaseRace,
      playerIdentity: harness.playerIdentity,
      streakFreeze: harness.streakFreeze,
    );

    expect(harness.userProfile.clearCalls, greaterThan(0));
    expect(harness.avatar.clearCalls, greaterThan(0));
    expect(harness.settings.lastUserId, isNull);
    expect(harness.cosmeticTarget.lastConfiguredUser, isNull);
    expect(harness.cosmeticPreview.lastConfiguredUser, isNull);
    expect(harness.weeklyFeatured.lastConfiguredUser, isNull);
    expect(harness.dailyReturn.lastConfiguredUser, isNull);
    expect(harness.season.lastConfiguredUser, isNull);
    expect(harness.chaseRace.lastConfiguredUser, isNull);
    expect(harness.playerIdentity.lastConfiguredUser, isNull);
    expect(harness.progress.recordedUserId, isNull);
    expect(harness.leaderboard.recordedToken, isNull);
    expect(harness.leaderboard.recordedIsDemoMode, isFalse);
    final pendingRaw = prefs.getString('pending_answers');
    expect(pendingRaw, isNotNull);
    final pending = List<Map<String, dynamic>>.from(jsonDecode(pendingRaw!));
    expect(pending.length, 1);
    expect(pending.first['user_id'], 'user-a');
  });

  test('rapid user switch keeps latest auth context on providers', () async {
    final auth = FakeAuthProvider(
      authenticated: true,
      token: 'token-a',
      userId: 'user-a',
      isDemoMode: false,
    );
    final harness = TestHarness();
    final coordinator = SessionCoordinator();

    await coordinator.synchronize(
      auth: auth,
      progress: harness.progress,
      quiz: harness.quiz,
      leaderboard: harness.leaderboard,
      userProfile: harness.userProfile,
      settings: harness.settings,
      avatar: harness.avatar,
      cosmeticTarget: harness.cosmeticTarget,
      cosmeticPreview: harness.cosmeticPreview,
      weeklyFeatured: harness.weeklyFeatured,
      dailyReturn: harness.dailyReturn,
      season: harness.season,
      chaseRace: harness.chaseRace,
      playerIdentity: harness.playerIdentity,
      streakFreeze: harness.streakFreeze,
    );

    auth.setSession(
      authenticated: true,
      token: 'token-b',
      userId: 'user-b',
      isDemoMode: true,
    );

    await coordinator.synchronize(
      auth: auth,
      progress: harness.progress,
      quiz: harness.quiz,
      leaderboard: harness.leaderboard,
      userProfile: harness.userProfile,
      settings: harness.settings,
      avatar: harness.avatar,
      cosmeticTarget: harness.cosmeticTarget,
      cosmeticPreview: harness.cosmeticPreview,
      weeklyFeatured: harness.weeklyFeatured,
      dailyReturn: harness.dailyReturn,
      season: harness.season,
      chaseRace: harness.chaseRace,
      playerIdentity: harness.playerIdentity,
      streakFreeze: harness.streakFreeze,
    );

    expect(harness.progress.recordedToken, 'token-b');
    expect(harness.progress.recordedUserId, 'user-b');
    expect(harness.progress.recordedIsDemoMode, isTrue);
    expect(harness.quiz.recordedToken, 'token-b');
    expect(harness.quiz.recordedIsDemoMode, isTrue);
    expect(harness.leaderboard.recordedToken, 'token-b');
    expect(harness.leaderboard.recordedIsDemoMode, isTrue);
  });

  test(
    'user switch clears progress and force-refreshes before daily return load',
    () async {
      final auth = FakeAuthProvider(
        authenticated: true,
        token: 'token-a',
        userId: 'user-a',
        isDemoMode: false,
      );
      final harness = TestHarness();
      final coordinator = SessionCoordinator();

      await coordinator.synchronize(
        auth: auth,
        progress: harness.progress,
        quiz: harness.quiz,
        leaderboard: harness.leaderboard,
        userProfile: harness.userProfile,
        settings: harness.settings,
        avatar: harness.avatar,
        cosmeticTarget: harness.cosmeticTarget,
        cosmeticPreview: harness.cosmeticPreview,
        weeklyFeatured: harness.weeklyFeatured,
        dailyReturn: harness.dailyReturn,
        season: harness.season,
        chaseRace: harness.chaseRace,
        playerIdentity: harness.playerIdentity,
        streakFreeze: harness.streakFreeze,
      );

      harness.progress.resetRecording();
      harness.dailyReturn.resetRecording();

      auth.setSession(
        authenticated: true,
        token: 'token-b',
        userId: 'user-b',
        isDemoMode: false,
      );

      await coordinator.synchronize(
        auth: auth,
        progress: harness.progress,
        quiz: harness.quiz,
        leaderboard: harness.leaderboard,
        userProfile: harness.userProfile,
        settings: harness.settings,
        avatar: harness.avatar,
        cosmeticTarget: harness.cosmeticTarget,
        cosmeticPreview: harness.cosmeticPreview,
        weeklyFeatured: harness.weeklyFeatured,
        dailyReturn: harness.dailyReturn,
        season: harness.season,
        chaseRace: harness.chaseRace,
        playerIdentity: harness.playerIdentity,
        streakFreeze: harness.streakFreeze,
      );

      expect(harness.progress.clearForUserSwitchCalls, 1);
      expect(harness.progress.loadProgressCalls, 1);
      expect(harness.progress.loadProgressForceRefreshArgs, [true]);
      expect(harness.dailyReturn.progressLoadCallsAtLastLoad, 1);
    },
  );
}

class FakeAuthProvider extends AuthProvider {
  FakeAuthProvider({
    required bool authenticated,
    required String? token,
    required String? userId,
    required bool isDemoMode,
  }) : _authenticated = authenticated,
       _token = token,
       _userId = userId,
       _isDemoMode = isDemoMode;

  bool _authenticated;
  String? _token;
  String? _userId;
  bool _isDemoMode;

  void setSession({
    required bool authenticated,
    required String? token,
    required String? userId,
    required bool isDemoMode,
  }) {
    _authenticated = authenticated;
    _token = token;
    _userId = userId;
    _isDemoMode = isDemoMode;
  }

  @override
  bool get isAuthenticated => _authenticated;

  @override
  String? get token => _token;

  @override
  String? get userId => _userId;

  @override
  bool get isDemoMode => _isDemoMode;
}

class RecordingProgressProvider extends ProgressProvider {
  RecordingProgressProvider() : super(enableDemoFallback: true);

  String? recordedToken;
  String? recordedUserId;
  bool? recordedIsDemoMode;
  int clearForUserSwitchCalls = 0;
  int loadProgressCalls = 0;
  final List<bool> loadProgressForceRefreshArgs = [];

  @override
  void updateAuthContext({
    String? token,
    required bool isDemoMode,
    String? userId,
  }) {
    recordedToken = token;
    recordedUserId = userId;
    recordedIsDemoMode = isDemoMode;
  }

  @override
  void clearForUserSwitch() {
    clearForUserSwitchCalls += 1;
  }

  @override
  Future<void> loadProgress({bool forceRefresh = false}) async {
    loadProgressCalls += 1;
    loadProgressForceRefreshArgs.add(forceRefresh);
  }

  void resetRecording() {
    clearForUserSwitchCalls = 0;
    loadProgressCalls = 0;
    loadProgressForceRefreshArgs.clear();
  }
}

class RecordingLeaderboardProvider extends LeaderboardProvider {
  RecordingLeaderboardProvider();

  String? recordedToken;
  bool? recordedIsDemoMode;

  @override
  void onTokenUpdated(String? newToken, {bool isDemoMode = false}) {
    recordedToken = newToken;
    recordedIsDemoMode = isDemoMode;
  }
}

class RecordingUserProfileProvider extends UserProfileProvider {
  int clearCalls = 0;
  int loadCalls = 0;

  @override
  void clear() {
    clearCalls += 1;
  }

  @override
  Future<void> load({bool forceRefresh = false}) async {
    loadCalls += 1;
  }
}

class RecordingSettingsProvider extends SettingsProvider {
  String? lastUserId;
  int syncCalls = 0;

  @override
  void setUserId(String? userId) {
    lastUserId = userId;
  }

  @override
  Future<void> syncFromBackend(String userId) async {
    syncCalls += 1;
    lastUserId = userId;
  }
}

class RecordingAvatarProvider extends AvatarProvider {
  int clearCalls = 0;
  int loadCalls = 0;

  @override
  void clear() {
    clearCalls += 1;
  }

  @override
  Future<void> load() async {
    loadCalls += 1;
  }
}

class RecordingCosmeticTargetProvider extends CosmeticTargetProvider {
  String? lastConfiguredUser;
  int loadCalls = 0;

  @override
  void configureUser(String? userId, {bool autoLoad = true}) {
    lastConfiguredUser = userId;
  }

  @override
  Future<void> load({String? userId}) async {
    lastConfiguredUser = userId;
    loadCalls += 1;
  }
}

class RecordingCosmeticPreviewProvider extends CosmeticPreviewProvider {
  String? lastConfiguredUser;

  @override
  void configureUser(String? userId) {
    lastConfiguredUser = userId;
  }
}

class RecordingWeeklyFeaturedProvider extends WeeklyFeaturedProvider {
  String? lastConfiguredUser;
  int loadCalls = 0;

  @override
  void configureUser(String? userId, {bool autoLoad = true}) {
    lastConfiguredUser = userId;
  }

  @override
  Future<void> load({String? userId, DateTime? now}) async {
    lastConfiguredUser = userId;
    loadCalls += 1;
  }
}

class RecordingDailyReturnProvider extends DailyReturnProvider {
  String? lastConfiguredUser;
  int loadCalls = 0;
  int? progressLoadCallsAtLastLoad;

  @override
  void configureUser(String? userId, {bool autoLoad = true}) {
    lastConfiguredUser = userId;
  }

  @override
  Future<void> load({
    String? userId,
    DateTime? now,
    ProgressProvider? progress,
    StreakFreezeProvider? streakFreeze,
    WeeklyFeaturedProvider? weeklyFeatured,
  }) async {
    lastConfiguredUser = userId;
    loadCalls += 1;
    if (progress is RecordingProgressProvider) {
      progressLoadCallsAtLastLoad = progress.loadProgressCalls;
    }
  }

  void resetRecording() {
    loadCalls = 0;
    progressLoadCallsAtLastLoad = null;
  }
}

class RecordingSeasonProvider extends SeasonProvider {
  String? lastConfiguredUser;
  int reloadCalls = 0;

  @override
  void configureUser(String? userId, {bool autoLoad = true}) {
    lastConfiguredUser = userId;
  }

  @override
  Future<void> reload({DateTime? now}) async {
    reloadCalls += 1;
  }
}

class RecordingChaseRaceProvider extends ChaseRaceProvider {
  String? lastConfiguredUser;
  int loadCalls = 0;
  CosmeticTarget? lastTarget;

  @override
  void configureUser(String? userId) {
    lastConfiguredUser = userId;
  }

  @override
  void updateTarget(CosmeticTarget? target) {
    lastTarget = target;
  }

  @override
  Future<void> loadRaceForTarget(CosmeticTarget? target) async {
    lastTarget = target;
    loadCalls += 1;
  }
}

class RecordingPlayerIdentityProvider extends PlayerIdentityProvider {
  String? lastConfiguredUser;

  @override
  void configureUser(String? userId, {bool autoLoad = true}) {
    lastConfiguredUser = userId;
  }
}

class TestHarness {
  final progress = RecordingProgressProvider();
  final quiz = RecordingQuizProvider();
  final leaderboard = RecordingLeaderboardProvider();
  final userProfile = RecordingUserProfileProvider();
  final settings = RecordingSettingsProvider();
  final avatar = RecordingAvatarProvider();
  final cosmeticTarget = RecordingCosmeticTargetProvider();
  final cosmeticPreview = RecordingCosmeticPreviewProvider();
  final weeklyFeatured = RecordingWeeklyFeaturedProvider();
  final dailyReturn = RecordingDailyReturnProvider();
  final season = RecordingSeasonProvider();
  final chaseRace = RecordingChaseRaceProvider();
  final playerIdentity = RecordingPlayerIdentityProvider();
  final streakFreeze = StreakFreezeProvider();
}

class RecordingQuizProvider extends QuizProvider {
  String? recordedToken;
  bool? recordedIsDemoMode;

  @override
  void updateAuthContext({String? token, bool isDemoMode = false}) {
    recordedToken = token;
    recordedIsDemoMode = isDemoMode;
  }
}
