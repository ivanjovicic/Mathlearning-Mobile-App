import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cosmetic_item.dart';
import '../models/season.dart';
import '../services/cosmetics_service.dart';
import '../services/season_service.dart';

class SeasonDailyRunPreview {
  const SeasonDailyRunPreview({required this.xpGained, this.milestoneReached});

  final int xpGained;
  final SeasonMilestone? milestoneReached;
}

class SeasonDailyRunAwardResult {
  const SeasonDailyRunAwardResult({
    required this.success,
    required this.applied,
    required this.queued,
    required this.transactionId,
    required this.xpGain,
    this.reason,
    this.retried = false,
  });

  final bool success;
  final bool applied;
  final bool queued;
  final String? transactionId;
  final int? xpGain;
  final String? reason;
  final bool retried;
}

class _PendingSeasonDailyRunAward {
  const _PendingSeasonDailyRunAward({
    required this.transactionId,
    required this.userId,
    required this.seasonId,
    required this.xpGain,
    required this.createdAtUtc,
  });

  final String transactionId;
  final String userId;
  final String seasonId;
  final int xpGain;
  final DateTime createdAtUtc;

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'userId': userId,
        'seasonId': seasonId,
        'xpGain': xpGain,
        'createdAtUtc': createdAtUtc.toIso8601String(),
      };

  factory _PendingSeasonDailyRunAward.fromJson(Map<String, dynamic> json) {
    return _PendingSeasonDailyRunAward(
      transactionId: json['transactionId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      seasonId: json['seasonId']?.toString() ?? '',
      xpGain: _asInt(json['xpGain']) ?? 0,
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

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
  Future<void>? _loadInFlight;
  Season? _season;
  SeasonProgress? _progress;

  /// Fired after a successful Daily Run — consumed once by the UI.
  int? _pendingSeasonXpGain;

  /// Milestone that was just reached — consumed once by the UI.
  SeasonMilestone? _pendingMilestoneReached;

  _PendingSeasonDailyRunAward? _pendingDailyRunAward;
  int _seasonAwardSequence = 0;

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

  /// Predicts season rewards for a Daily Run without mutating persisted state.
  SeasonDailyRunPreview? previewDailyRunXp(double streakMultiplier) {
    final season = _season;
    final userId = _userId;
    if (season == null || userId == null) return null;
    if (season.status(DateTime.now()) == SeasonStatus.ended) return null;

    final xpGain = _service.dailyRunSeasonXp(streakMultiplier);
    final current =
        _progress ??
        SeasonProgress.empty(seasonId: season.seasonId, userId: userId);
    final prevXp = current.earnedXp;
    final newXp = (prevXp + xpGain).clamp(0, season.totalXpGoal * 2);

    SeasonMilestone? reached;
    for (final milestone in season.milestones) {
      if (prevXp < milestone.xpRequired &&
          newXp >= milestone.xpRequired &&
          !current.claimedMilestoneIds.contains(milestone.id)) {
        reached = milestone;
        break;
      }
    }

    return SeasonDailyRunPreview(xpGained: xpGain, milestoneReached: reached);
  }

  // ── Lifecycle ──────────────────────────────────────────────────

  void configureUser(String? userId, {bool autoLoad = true}) {
    final safeId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    if (_userId == safeId) return;
    _userId = safeId;
    _season = null;
    _progress = null;
    _pendingSeasonXpGain = null;
    _pendingMilestoneReached = null;
    _pendingDailyRunAward = null;
    _loadInFlight = null;
    _isLoading = true;
    notifyListeners();
    if (autoLoad) {
      unawaited(_startLoad(safeId));
    } else {
      _isLoading = false;
      notifyListeners();
    }
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
    _pendingDailyRunAward = null;
    _loadInFlight = null;
    _isLoading = true;
    notifyListeners();
    await _startLoad(safeId);
  }

  Future<void> reload({DateTime? now}) async {
    final uid = _userId;
    if (uid == null) return;
    _isLoading = true;
    notifyListeners();
    await _startLoad(uid, now: now);
  }

  Future<void> _startLoad(String userId, {DateTime? now}) {
    final inFlight = _loadInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final task = _load(userId, now: now).whenComplete(() {
      _loadInFlight = null;
    });
    _loadInFlight = task;
    return task;
  }

  Future<void> _ensureLoaded({DateTime? now}) async {
    final userId = _userId;
    if (userId == null) return;
    await _startLoad(userId, now: now);
    if (_season != null && _progress != null) {
      return;
    }
    await _startLoad(userId, now: now);
  }

  Future<void> _load(String userId, {DateTime? now}) async {
    try {
      final season = await _service.loadActiveSeason(now: now);
      if (_userId != userId) return;
      _season = season;
      if (season != null) {
        _progress = await _service.loadProgress(
          seasonId: season.seasonId,
          userId: userId,
        );
        await _reconcilePendingDailyRunAwardIfNeeded(
          season: season,
          userId: userId,
        );
      }
    } catch (e) {
      debugPrint('[SeasonProvider] load failed: $e');
    } finally {
      if (_userId == userId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // ── Season XP ──────────────────────────────────────────────────

  /// Awards season XP for a completed Daily Run.
  ///
  /// [streakMultiplier] should come from [DailyRunProvider.displayedXpMultiplier].
  Future<SeasonDailyRunAwardResult> awardDailyRunXp(
    double streakMultiplier,
  ) async {
    final userId = _userId;
    if (userId == null) {
      return const SeasonDailyRunAwardResult(
        success: false,
        applied: false,
        queued: false,
        transactionId: null,
        xpGain: null,
        reason: 'Not logged in',
      );
    }

    await _ensureLoaded();
    final season = _season;
    if (season == null) {
      return _queuePendingDailyRunAward(
        userId: userId,
        streakMultiplier: streakMultiplier,
        reason: 'Season unavailable',
      );
    }

    final now = DateTime.now();
    if (season.status(now) == SeasonStatus.ended) {
      return const SeasonDailyRunAwardResult(
        success: false,
        applied: false,
        queued: false,
        transactionId: null,
        xpGain: null,
        reason: 'Season has ended',
      );
    }

    final existingPending = await _loadPendingDailyRunAward();
    if (existingPending != null &&
        existingPending.userId == userId &&
        (existingPending.seasonId.isEmpty ||
            existingPending.seasonId == season.seasonId)) {
      final applied = await _reconcilePendingDailyRunAwardIfNeeded(
        season: season,
        userId: userId,
      );
      return SeasonDailyRunAwardResult(
        success: applied || _pendingDailyRunAward != null,
        applied: applied,
        queued: _pendingDailyRunAward != null,
        transactionId: existingPending.transactionId,
        xpGain: existingPending.xpGain,
        reason: applied ? null : 'Pending award retained for retry',
        retried: true,
      );
    }

    return _queuePendingDailyRunAward(
      userId: userId,
      streakMultiplier: streakMultiplier,
      season: season,
    );
  }

  Future<SeasonDailyRunAwardResult> _queuePendingDailyRunAward({
    required String userId,
    required double streakMultiplier,
    Season? season,
    String? seasonId,
    String? reason,
  }) async {
    final xpGain = _service.dailyRunSeasonXp(streakMultiplier);
    final resolvedSeasonId = season?.seasonId ?? seasonId ?? _season?.seasonId ?? '';
    final pending = _PendingSeasonDailyRunAward(
      transactionId: _newSeasonAwardTransactionId(),
      userId: userId,
      seasonId: resolvedSeasonId,
      xpGain: xpGain,
      createdAtUtc: DateTime.now().toUtc(),
    );
    _pendingDailyRunAward = pending;
    try {
      await _persistPendingDailyRunAward(pending);
    } catch (e) {
      debugPrint('[SeasonProvider] failed to persist pending award: $e');
    }

    var applied = false;
    if (season != null) {
      applied = await _applyDailyRunAwardTransaction(
        pending,
        season: season,
        userId: userId,
      );
      if (applied) {
        await _clearPendingDailyRunAward();
      }
    }

    return SeasonDailyRunAwardResult(
      success: true,
      applied: applied,
      queued: !applied,
      transactionId: pending.transactionId,
      xpGain: xpGain,
      reason: applied ? null : (reason ?? 'Pending award queued for retry'),
    );
  }

  Future<bool> _applyDailyRunAwardTransaction(
    _PendingSeasonDailyRunAward pending, {
    required Season season,
    required String userId,
  }) async {
    if (_progress?.appliedDailyRunTransactionIds
            .contains(pending.transactionId) ==
        true) {
      _pendingSeasonXpGain = pending.xpGain;
      return true;
    }

    final current =
        _progress ??
        SeasonProgress.empty(seasonId: season.seasonId, userId: userId);
    final prevXp = current.earnedXp;
    final newXp = (prevXp + pending.xpGain).clamp(0, season.totalXpGoal * 2);
    final updated = current.copyWith(
      earnedXp: newXp,
      appliedDailyRunTransactionIds: {
        ...current.appliedDailyRunTransactionIds,
        pending.transactionId,
      },
    );

    _progress = updated;
    _pendingSeasonXpGain = pending.xpGain;
    _pendingMilestoneReached = _detectMilestoneCrossing(
      season: season,
      previous: current,
      updated: updated,
    );

    notifyListeners();
    final persisted = await _service.saveProgress(updated);
    if (!persisted) {
      debugPrint(
        '[SeasonProvider] awardDailyRunXp: failed to persist progress',
      );
      return false;
    }
    return true;
  }

  Future<bool> _reconcilePendingDailyRunAwardIfNeeded({
    required Season season,
    required String userId,
  }) async {
    final pending = await _loadPendingDailyRunAward();
    if (pending == null ||
        pending.userId != userId ||
        (pending.seasonId.isNotEmpty && pending.seasonId != season.seasonId)) {
      return false;
    }

    final applied = await _applyDailyRunAwardTransaction(
      pending,
      season: season,
      userId: userId,
    );
    if (applied) {
      await _clearPendingDailyRunAward();
    }
    return applied;
  }

  // ── Milestone claiming ─────────────────────────────────────────

  Future<_PendingSeasonDailyRunAward?> _loadPendingDailyRunAward() async {
    if (_pendingDailyRunAward != null) {
      return _pendingDailyRunAward;
    }

    final userId = _userId;
    if (userId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingDailyRunAwardKey(userId));
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _pendingDailyRunAward = _PendingSeasonDailyRunAward.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[SeasonProvider] failed to parse pending award: $e');
      _pendingDailyRunAward = null;
    }
    return _pendingDailyRunAward;
  }

  Future<void> _persistPendingDailyRunAward(
    _PendingSeasonDailyRunAward pending,
  ) async {
    final userId = _userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingDailyRunAwardKey(userId),
      jsonEncode(pending.toJson()),
    );
  }

  Future<void> _clearPendingDailyRunAward() async {
    _pendingDailyRunAward = null;
    final userId = _userId;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingDailyRunAwardKey(userId));
  }

  String _pendingDailyRunAwardKey(String userId) =>
      'season_pending_daily_run_award.v1.$userId';

  String _newSeasonAwardTransactionId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _seasonAwardSequence += 1;
    return 'season_daily_run_${_userId ?? 'local'}_${now}_$_seasonAwardSequence';
  }

  SeasonMilestone? _detectMilestoneCrossing({
    required Season season,
    required SeasonProgress previous,
    required SeasonProgress updated,
  }) {
    for (final milestone in season.milestones) {
      if (previous.earnedXp < milestone.xpRequired &&
          updated.earnedXp >= milestone.xpRequired &&
          !previous.claimedMilestoneIds.contains(milestone.id)) {
        return milestone;
      }
    }
    return null;
  }

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
    final persisted = await _service.saveProgress(updated);
    if (!persisted) {
      debugPrint('[SeasonProvider] claimMilestone: failed to persist progress');
    }

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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
