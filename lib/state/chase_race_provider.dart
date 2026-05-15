import 'package:flutter/foundation.dart';

import '../models/chase_race.dart';
import '../models/cosmetic_target.dart';
import '../services/chase_race_service.dart';

/// Manages the real-time chase race for the current user's cosmetic target.
///
/// **Design contract:**
/// - Race data comes exclusively from the backend (or a prior cached backend
///   response). No synthetic participant data is ever fabricated.
/// - If neither the backend nor cache has data, [race] is null and no race
///   UI appears.
/// - Catch-up messages ([catchUpMessages]) are derived only from real [race]
///   data — every name in a message is a real participant.
/// - The current user's own progress row is always kept accurate using their
///   local [CosmeticTarget] data (merged via [_mergeCurrentUser]).
///
/// Lifecycle: call [configureUser] when auth changes, [updateTarget] when the
/// chase target changes, and [loadRaceForTarget] from an orchestrator/listener
/// outside `ProxyProvider.update`.
class ChaseRaceProvider extends ChangeNotifier {
  ChaseRaceProvider({ChaseRaceService? service})
    : _service = service ?? ChaseRaceService.instance;

  final ChaseRaceService _service;

  String? _userId;
  ChaseRace? _race;
  bool _isLoading = false;
  String? _loadedItemId;

  // ── Getters ─────────────────────────────────────────────────────────────────

  bool get isLoading => _isLoading;

  /// The current race snapshot, or null if unavailable.
  ChaseRace? get race => _race;

  /// The current user's own race entry, or null if not in the race.
  ChaseRaceEntry? get myEntry {
    final uid = _userId;
    if (uid == null) return null;
    return _race?.entryFor(uid);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  /// Call when auth state changes. Resets race if the user switches.
  void configureUser(String? userId) {
    final safeId = userId == null || userId.trim().isEmpty
        ? 'local'
        : userId.trim();
    if (_userId == safeId) return;
    _userId = safeId;
    _race = null;
    _loadedItemId = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Called from wiring code to keep target snapshot in sync.
  /// Does not trigger network work directly.
  void updateTarget(CosmeticTarget? target) {
    final userId = _userId;
    if (userId == null || target == null) {
      if (_race != null || _isLoading || _loadedItemId != null) {
        _race = null;
        _isLoading = false;
        _loadedItemId = null;
        notifyListeners();
      }
      return;
    }

    if (target.targetCosmeticItemId == _loadedItemId && !_isLoading) {
      _mergeLocalProgress(target, userId);
      return;
    }

    if (_race?.itemId != target.targetCosmeticItemId) {
      _race = null;
      notifyListeners();
    }
  }

  /// Loads (or refreshes) the race for [target].
  ///
  /// - If the target item changed, clears the current race and fetches fresh
  ///   data.
  /// - If the item is the same, merges the updated local progress without an
  ///   extra network call.
  Future<void> loadRaceForTarget(CosmeticTarget? target) async {
    final userId = _userId;

    if (userId == null || target == null) {
      if (_race != null || _isLoading) {
        _race = null;
        _isLoading = false;
        _loadedItemId = null;
        notifyListeners();
      }
      return;
    }

    final itemId = target.targetCosmeticItemId;

    // Same item — just re-merge local progress without a network round-trip.
    if (itemId == _loadedItemId && !_isLoading) {
      _mergeLocalProgress(target, userId);
      return;
    }

    _isLoading = true;
    _loadedItemId = itemId;
    if (_race?.itemId != itemId) _race = null;
    notifyListeners();

    final fetched = await _service.loadRace(itemId: itemId, userId: userId);

    // Guard: target may have changed while we were awaiting.
    if (_loadedItemId != itemId) return;

    _isLoading = false;
    if (fetched != null) {
      _race = _mergeCurrentUser(fetched, target, userId);
    } else {
      // Backend unavailable and no cache — show nothing. Never fabricate data.
      _race = null;
    }
    notifyListeners();
  }

  /// Updates the current user's fragment count after a Daily Run without
  /// triggering a full network reload.
  void applyLocalProgressUpdate(CosmeticTarget target) {
    final userId = _userId;
    if (userId == null || _race == null) return;
    if (target.targetCosmeticItemId != _race!.itemId) return;
    _mergeLocalProgress(target, userId);
  }

  // ── Derived state ────────────────────────────────────────────────────────────

  /// Returns contextual catch-up messages based *only* on real race data.
  ///
  /// Returns an empty list when no race is loaded, the current user is not
  /// in the race, or no actionable situation is detected.
  List<String> get catchUpMessages {
    final race = _race;
    final userId = _userId;
    if (race == null || userId == null || !race.hasCompetitors) {
      return const [];
    }
    final me = race.entryFor(userId);
    if (me == null) return const [];

    final messages = <String>[];
    final myRank = me.rank;

    // "You passed X today" — only when we gained fragments today and moved
    // above someone who didn't gain anything today.
    if (me.todayGained > 0) {
      final passed = race.participants
          .where(
            (e) => e.userId != userId && e.rank > myRank && e.todayGained == 0,
          )
          .firstOrNull;
      if (passed != null) {
        messages.add('You passed ${passed.displayName} today!');
      }
    }

    // "X is 1 fragment away!" — truthful fact about a competitor.
    final almostDone = race.participants
        .where(
          (e) =>
              e.userId != userId && !e.isComplete && e.remainingFragments == 1,
        )
        .firstOrNull;
    if (almostDone != null) {
      messages.add('${almostDone.displayName} is 1 fragment away!');
    }

    // "N more run(s) to pass X" — when the gap to the person ahead is small.
    if (myRank > 1 && !me.isComplete) {
      final ahead = race.participants
          .where((e) => e.rank == myRank - 1)
          .firstOrNull;
      if (ahead != null && !ahead.isComplete) {
        final gap = ahead.fragmentsOwned - me.fragmentsOwned;
        if (gap > 0 && gap <= 3) {
          messages.add(
            '$gap more run${gap > 1 ? "s" : ""} to pass ${ahead.displayName}!',
          );
        }
      }
    }

    // "You fell behind X today" — only when we gained nothing and someone
    // above us did gain today.
    if (messages.isEmpty && me.todayGained == 0 && myRank > 1) {
      final movedAhead = race.participants
          .where(
            (e) => e.userId != userId && e.rank < myRank && e.todayGained > 0,
          )
          .firstOrNull;
      if (movedAhead != null) {
        messages.add('You fell behind ${movedAhead.displayName} today.');
      }
    }

    // Generic catch-up prompt when nothing more specific applies.
    if (messages.isEmpty && myRank > 1 && !me.isComplete) {
      final leader = race.participants.where((e) => e.rank == 1).firstOrNull;
      if (leader != null && leader.userId != userId) {
        messages.add('Catch up to ${leader.displayName}!');
      }
    }

    return messages;
  }

  /// True if [userId] is the first to have completed the current chase.
  bool isFirstFinisher(String userId) => _race?.firstFinisher?.userId == userId;

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _mergeLocalProgress(CosmeticTarget target, String userId) {
    final current = _race;
    if (current == null) return;
    _race = _mergeCurrentUser(current, target, userId);
    notifyListeners();
  }

  /// Replaces the current user's race entry with authoritative local data.
  ChaseRace _mergeCurrentUser(
    ChaseRace race,
    CosmeticTarget target,
    String userId,
  ) {
    final existing = race.entryFor(userId);
    final myEntry = ChaseRaceEntry(
      userId: userId,
      displayName: existing?.displayName ?? '',
      avatarUrl: existing?.avatarUrl,
      cosmeticLoadout: existing?.cosmeticLoadout,
      itemId: target.targetCosmeticItemId,
      fragmentsOwned: target.targetFragmentsOwned,
      fragmentsRequired: target.targetFragmentsRequired,
      todayGained: existing?.todayGained ?? 0,
      // Preserve backend-assigned completedAt; fall back to now only when the
      // target was just completed locally and the backend hasn't caught up yet.
      completedAt: target.isComplete
          ? (existing?.completedAt ?? DateTime.now())
          : null,
      rank: existing?.rank ?? 0,
    );
    return race.withUpdatedEntry(myEntry);
  }

  // ── Test hooks ───────────────────────────────────────────────────────────────

  @visibleForTesting
  ChaseRaceService get debugService => _service;

  @visibleForTesting
  Future<void> configureUserAndWait(String? userId) async {
    configureUser(userId);
  }
}
