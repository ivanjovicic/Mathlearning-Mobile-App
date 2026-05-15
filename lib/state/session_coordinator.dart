import 'package:flutter/foundation.dart';

import 'adaptive_provider.dart';
import 'auth_provider.dart';
import 'avatar_provider.dart';
import 'chase_race_provider.dart';
import 'cosmetic_preview_provider.dart';
import 'cosmetic_target_provider.dart';
import 'daily_return_provider.dart';
import 'leaderboard_provider.dart';
import 'player_identity_provider.dart';
import 'progress_provider.dart';
import 'quiz_provider.dart';
import 'season_provider.dart';
import 'settings_provider.dart';
import 'streak_freeze_provider.dart';
import 'user_profile_provider.dart';
import '../services/user_scoped_storage.dart';
import 'weekly_featured_provider.dart';

/// Centralizes auth-session transitions for user-scoped providers.
///
/// This keeps network side effects out of `ProxyProvider.update` callbacks
/// and applies a predictable reconciliation sequence on login/logout.
class SessionCoordinator {
  String? _lastSessionKey;
  String? _lastScopedUserId;
  int _revision = 0;

  Future<void> synchronize({
    required AuthProvider auth,
    required ProgressProvider progress,
    required QuizProvider quiz,
    required LeaderboardProvider leaderboard,
    required UserProfileProvider userProfile,
    required SettingsProvider settings,
    required AvatarProvider avatar,
    required CosmeticTargetProvider cosmeticTarget,
    required CosmeticPreviewProvider cosmeticPreview,
    required WeeklyFeaturedProvider weeklyFeatured,
    required DailyReturnProvider dailyReturn,
    required SeasonProvider season,
    required ChaseRaceProvider chaseRace,
    required PlayerIdentityProvider playerIdentity,
    required StreakFreezeProvider streakFreeze,
    AdaptiveProvider? adaptive,
  }) async {
    final scopedUserId = auth.isAuthenticated ? auth.userId : null;
    final sessionKey =
        '${auth.isAuthenticated}|${scopedUserId ?? ''}|${auth.isDemoMode}|${auth.token ?? ''}';
    if (_lastSessionKey == sessionKey) {
      return;
    }

    _lastSessionKey = sessionKey;
    final revision = ++_revision;
    bool isStale() => revision != _revision;

    // Always propagate auth context first.
    final previousScopedUserId = _lastScopedUserId;
    progress.updateAuthContext(
      token: auth.token,
      isDemoMode: auth.isDemoMode,
      userId: scopedUserId,
    );
    leaderboard.onTokenUpdated(auth.token, isDemoMode: auth.isDemoMode);
    quiz.token = auth.token;

    if (previousScopedUserId != null && previousScopedUserId != scopedUserId) {
      await UserScopedStorage.clearUserScopedData(previousScopedUserId);
    }

    if (!auth.isAuthenticated || scopedUserId == null) {
      _lastScopedUserId = null;
      userProfile.lastUserId = null;
      userProfile.clear();
      settings.setUserId(null);
      avatar.clear();
      cosmeticTarget.configureUser(null, autoLoad: false);
      cosmeticPreview.configureUser(null);
      weeklyFeatured.configureUser(null, autoLoad: false);
      dailyReturn.configureUser(null, autoLoad: false);
      season.configureUser(null, autoLoad: false);
      chaseRace.configureUser(null);
      chaseRace.updateTarget(null);
      playerIdentity.configureUser(null);
      adaptive?.updateFromProgress(progress);
      return;
    }

    final userChanged = _lastScopedUserId != scopedUserId;
    _lastScopedUserId = scopedUserId;

    // Step 1: Clear/scope user-bound providers.
    settings.setUserId(scopedUserId);
    cosmeticTarget.configureUser(scopedUserId, autoLoad: false);
    cosmeticPreview.configureUser(scopedUserId);
    weeklyFeatured.configureUser(scopedUserId, autoLoad: false);
    dailyReturn.configureUser(scopedUserId, autoLoad: false);
    season.configureUser(scopedUserId, autoLoad: false);
    chaseRace.configureUser(scopedUserId);
    playerIdentity.configureUser(scopedUserId);

    if (userChanged) {
      userProfile.lastUserId = scopedUserId;
      userProfile.clear();
      avatar.clear();
    }

    // Step 2: Load user-scoped network/state in a controlled order.
    try {
      await settings.syncFromBackend(scopedUserId);
      if (isStale()) return;

      await userProfile.load(forceRefresh: userChanged);
      if (isStale()) return;

      await avatar.load();
      if (isStale()) return;

      await weeklyFeatured.load(userId: scopedUserId);
      if (isStale()) return;

      await cosmeticTarget.load(userId: scopedUserId);
      if (isStale()) return;

      await season.reload();
      if (isStale()) return;

      await dailyReturn.load(
        userId: scopedUserId,
        progress: progress,
        streakFreeze: streakFreeze,
        weeklyFeatured: weeklyFeatured,
      );
      if (isStale()) return;

      await chaseRace.loadRaceForTarget(cosmeticTarget.target);
    } catch (e) {
      debugPrint('[SessionCoordinator] session sync failed: $e');
    }
  }
}
