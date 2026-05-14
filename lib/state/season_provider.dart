import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/cosmetic_item.dart';
import '../models/season.dart';
import '../services/cosmetics_service.dart';
import '../services/season_service.dart';

/// Drives the Mini Seasons feature: loads the active season, tracks per-user
/// season XP, handles milestone claiming, and supports season reset.
///
/// Lifecycle mirrors other user-scoped providers (CosmeticTargetProvider,
/// WeeklyFeaturedProvider): call [configureUser] when auth changes.
class SeasonProvider extends ChangeNotifier {
  SeasonProvider({SeasonService? service})
    : _service = service ?? SeasonService.instance;

  final SeasonService _service;

  /// Exposed for tests only — allows assertions on the injected service.
  @visibleForTesting
  SeasonService get debugService => _service;

  String? _userId;
  bool _isLoading = false;
  Season? _season;
  SeasonProgress? _progress;

  /// Fired after a successful Daily Run — consumed once by the UI.
  int? _pendingSeasonXpGain;

  /// Milestone that was just reached — consumed once by the UI.
  SeasonMilestone? _pendingMilestoneReached;

  // ── Getters ────────────────────────────────────────────────────

  bool get isLoading => _isLoading;
  Season? get season => _season;
  SeasonProgress? get progress => _progress;
  SeasonStatus get status =>
      _season?.status(DateTime.now()) ?? SeasonStatus.ended;

  int get earnedXp => _progress?.earnedXp ?? 0;
  int get totalXpGoal => _season?.totalXpGoal ?? 500;
  double get progressFraction => _season?.progressFraction(earnedXp) ?? 0;
  int get completionPercent => _season?.completionPercent(earnedXp) ?? 0;

  List<SeasonMilestone> get milestones => _season?.milestones ?? const [];

  List<SeasonMilestone> get reachedMilestones =>
      _season?.reachedMilestones(earnedXp) ?? const [];

  SeasonMilestone? get nextMilestone => _season?.nextMilestone(earnedXp);

  Set<String> get claimedMilestoneIds =>
      _progress?.claimedMilestoneIds ?? const {};

  bool canClaimMilestone(SeasonMilestone milestone) {
    final s = _season;
    if (s == null) return false;
    if (claimedMilestoneIds.contains(milestone.id)) return false;
    if (earnedXp < milestone.xpRequired) return false;
    // Cannot claim rewards after season has ended.
    final st = status;
    return st != SeasonStatus.ended;
  }

  bool isMilestoneClaimed(String milestoneId) =>
      claimedMilestoneIds.contains(milestoneId);

  /// Pending season XP gain from the last Daily Run — consumed once.
  int? takePendingXpGain() {
    final v = _pendingSeasonXpGain;
    _pendingSeasonXpGain = null;
    return v;
  }

  /// Milestone that was first reached with the last XP award — consumed once.
  SeasonMilestone? takePendingMilestoneReached() {
    final v = _pendingMilestoneReached;
    _pendingMilestoneReached = null;
    return v;
  }

  // ── Lifecycle ──────────────────────────────────────────────────

  void configureUser(String? userId) {
    final safeId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    if (_userId == safeId) return;
    _userId = safeId;
    _season = null;
    _progress = null;
    _pendingSeasonXpGain = null;
    _pendingMilestoneReached = null;
    _isLoading = true;
    notifyListeners();
    unawaited(_load(safeId));
  }

  /// Variant of [configureUser] that awaits the initial load — for tests only.
  @visibleForTesting
  Future<void> configureUserAndWait(String? userId) async {
    final safeId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    if (_userId == safeId) return;
    _userId = safeId;
    _season = null;
    _progress = null;
    _pendingSeasonXpGain = null;
    _pendingMilestoneReached = null;
    _isLoading = true;
    notifyListeners();
    await _load(safeId);
  }

  Future<void> reload({DateTime? now}) async {
    final uid = _userId;
    if (uid == null) return;
    _isLoading = true;
    notifyListeners();
    await _load(uid, now: now);
  }

  Future<void> _load(String userId, {DateTime? now}) async {
    final season = await _service.loadActiveSeason(now: now);
    if (_userId != userId) return;
    _season = season;
    if (season != null) {
      _progress = await _service.loadProgress(
        seasonId: season.seasonId,
        userId: userId,
      );
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Season XP ──────────────────────────────────────────────────

  /// Awards season XP for a completed Daily Run.
  ///
  /// [streakMultiplier] should come from [DailyRunProvider.displayedXpMultiplier].
  Future<void> awardDailyRunXp(double streakMultiplier) async {
    final season = _season;
    final userId = _userId;
    if (season == null || userId == null) return;
    if (season.status(DateTime.now()) == SeasonStatus.ended) return;

    final xpGain = _service.dailyRunSeasonXp(streakMultiplier);
    final current = _progress ?? SeasonProgress.empty(
      seasonId: season.seasonId,
      userId: userId,
    );

    final prevXp = current.earnedXp;
    final newXp = (prevXp + xpGain).clamp(0, season.totalXpGoal * 2);
    final updated = current.copyWith(earnedXp: newXp);

    _progress = updated;
    _pendingSeasonXpGain = xpGain;

    // Detect if a milestone threshold was crossed for the first time.
    for (final milestone in season.milestones) {
      if (prevXp < milestone.xpRequired &&
          newXp >= milestone.xpRequired &&
          !current.claimedMilestoneIds.contains(milestone.id)) {
        _pendingMilestoneReached = milestone;
        break; // Only surface the first newly-crossed milestone per run.
      }
    }

    notifyListeners();
    await _service.saveProgress(updated);
  }

  // ── Milestone claiming ─────────────────────────────────────────

  Future<SeasonMilestoneClaimResult> claimMilestone(
    SeasonMilestone milestone,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return SeasonMilestoneClaimResult(
        milestone: milestone,
        success: false,
        errorReason: 'Not logged in',
      );
    }

    if (!canClaimMilestone(milestone)) {
      return SeasonMilestoneClaimResult(
        milestone: milestone,
        success: false,
        errorReason: isMilestoneClaimed(milestone.id)
            ? 'Already claimed'
            : status == SeasonStatus.ended
            ? 'Season has ended'
            : 'Milestone not yet reached',
      );
    }

    // Grant the reward through the real service (cosmetics / badges).
    final granted = await _service.grantMilestoneReward(
      milestone: milestone,
      userId: userId,
    );

    if (!granted) {
      return SeasonMilestoneClaimResult(
        milestone: milestone,
        success: false,
        errorReason: 'Reward grant failed',
      );
    }

    final current = _progress!;
    final updated = current.copyWith(
      claimedMilestoneIds: {...current.claimedMilestoneIds, milestone.id},
    );
    _progress = updated;
    notifyListeners();
    await _service.saveProgress(updated);

    return SeasonMilestoneClaimResult(milestone: milestone, success: true);
  }

  // ── Season reset ───────────────────────────────────────────────

  /// Call when the active season has ended and a new one is ready.
  /// Preserves owned cosmetics (in CosmeticsService inventory).
  /// Archives earned badge IDs into the new progress record.
  Future<void> onSeasonReset({required String nextSeasonId}) async {
    final userId = _userId;
    final current = _progress;
    if (userId == null || current == null) return;

    final newProgress = await _service.resetForNewSeason(
      expiredProgress: current,
      nextSeasonId: nextSeasonId,
    );
    _progress = newProgress;

    // Reload the new season data.
    await _load(userId);
  }

  // ── Chase Race integration ─────────────────────────────────────

  /// Returns true if [itemId] is the featured legendary cosmetic of the active
  /// season. Used to boost visual priority on the chase card.
  bool isSeasonFeaturedItem(String itemId) {
    return _season?.featuredLegendaryCosmeticId == itemId;
  }

  /// Returns the season's featured cosmetic from the catalog, or null if no
  /// active season or item not found.
  CosmeticItem? get featuredCosmeticItem {
    final id = _season?.featuredLegendaryCosmeticId;
    if (id == null) return null;
    return CosmeticsService.instance
        .getCatalog()
        .where((item) => item.id == id)
        .firstOrNull;
  }
}
