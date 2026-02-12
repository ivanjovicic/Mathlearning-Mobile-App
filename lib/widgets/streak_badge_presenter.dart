import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/progress_provider.dart';
import '../state/streak_freeze_provider.dart';
import '../state/streak_state_machine.dart';
import 'animated_streak_badge.dart';
import 'streak_freeze_shop_sheet.dart';

/// Single place to control streak visuals + freeze messaging.
///
/// - reads [ProgressProvider.takeStreakRollEvent] once
/// - shows [StreakVisualState.protected] briefly (auto-clear)
/// - shows [StreakVisualState.atRisk] after [atRiskHour] if user hasn't done activity today
/// - keeps [StreakVisualState.lost] until user does activity today
class StreakBadgePresenter extends StatefulWidget {
  final VoidCallback? onTap;
  final bool showSnackbars;

  /// Local-time hour after which the badge can switch to `atRisk`.
  ///
  /// Example: 20 => 8PM.
  final int atRiskHour;

  /// How long the "protected" state should remain before switching back.
  final Duration protectedHold;

  const StreakBadgePresenter({
    super.key,
    this.onTap,
    this.showSnackbars = true,
    this.atRiskHour = 20,
    this.protectedHold = const Duration(milliseconds: 2600),
  });

  @override
  State<StreakBadgePresenter> createState() => _StreakBadgePresenterState();
}

class _StreakBadgePresenterState extends State<StreakBadgePresenter> {
  late final StreakStateMachine _machine = StreakStateMachine(
    state: StreakVisualState.normal,
    streakDays: 0,
    freezeCount: 0,
  );

  ProgressProvider? _progress;
  StreakFreezeProvider? _freeze;

  Timer? _protectedClearTimer;
  Timer? _atRiskTimer;
  Timer? _midnightTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final freeze = Provider.of<StreakFreezeProvider>(context, listen: false);

    if (!identical(progress, _progress)) {
      _progress?.removeListener(_onProgressChanged);
      _progress = progress..addListener(_onProgressChanged);
    }

    if (!identical(freeze, _freeze)) {
      _freeze?.removeListener(_onFreezeChanged);
      _freeze = freeze..addListener(_onFreezeChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncFromProviders();
    });
  }

  @override
  void dispose() {
    _protectedClearTimer?.cancel();
    _atRiskTimer?.cancel();
    _midnightTimer?.cancel();

    _progress?.removeListener(_onProgressChanged);
    _freeze?.removeListener(_onFreezeChanged);
    super.dispose();
  }

  void _onProgressChanged() => _syncFromProviders();
  void _onFreezeChanged() => _syncFromProviders();

  bool _isAtRiskNow() => DateTime.now().hour >= widget.atRiskHour;

  void _scheduleProtectedClear() {
    _protectedClearTimer?.cancel();
    _protectedClearTimer = Timer(widget.protectedHold, () {
      if (!mounted) return;
      setState(() => _machine.clearProtected());
      _scheduleAtRiskTimer();
    });
  }

  void _scheduleAtRiskTimer() {
    _atRiskTimer?.cancel();
    final progress = _progress;
    if (!mounted || progress == null) return;

    if (progress.isStreakDoneToday) return;
    if (_machine.state != StreakVisualState.normal) return;

    final now = DateTime.now();
    final threshold = DateTime(now.year, now.month, now.day, widget.atRiskHour);
    if (now.isAfter(threshold)) return;

    _atRiskTimer = Timer(threshold.difference(now), () {
      if (!mounted) return;
      final progress = _progress;
      if (progress == null) return;
      if (progress.isStreakDoneToday) return;
      if (_machine.state != StreakVisualState.normal) return;
      setState(() => _machine.onAtRisk());
    });
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final delay = nextMidnight.difference(now) + const Duration(seconds: 2);
    _midnightTimer = Timer(delay, () {
      if (!mounted) return;
      _syncFromProviders();
    });
  }

  void _showSnackBarForEvent({required int used, required bool broken}) {
    if (!widget.showSnackbars) return;

    final cs = Theme.of(context).colorScheme;
    final message = broken
        ? (used > 0
              ? 'Potroseno je $used Streak Freeze, ali je streak ipak pukao.'
              : 'Streak je resetovan (propusteno vise dana).')
        : 'Streak Freeze aktiviran! Sacuvan streak (x$used).';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: broken ? cs.errorContainer : cs.tertiaryContainer,
        ),
      );
    });
  }

  void _syncFromProviders() {
    if (!mounted) return;
    final progress = _progress;
    final freeze = _freeze;
    if (progress == null || freeze == null) return;

    final prevState = _machine.state;
    final prevStreak = _machine.streakDays;
    final prevFreeze = _machine.freezeCount;

    _machine.syncCounts(streakDays: progress.streak, freezeCount: freeze.count);

    final doneToday = progress.isStreakDoneToday;
    if (doneToday) {
      _protectedClearTimer?.cancel();
      _protectedClearTimer = null;
      _machine.onDailyActivity();
    }

    final event = progress.takeStreakRollEvent();
    if (event != null) {
      final used = event.freezesUsed;
      final broken = event.streakBroken;

      if (used > 0 || broken) {
        if (broken) {
          _protectedClearTimer?.cancel();
          _protectedClearTimer = null;
          _machine.state = StreakVisualState.lost;
        } else if (!doneToday && used > 0) {
          _machine.state = StreakVisualState.protected;
          _scheduleProtectedClear();
        }

        _showSnackBarForEvent(used: used, broken: broken);
      }
    }

    if (!doneToday &&
        _machine.state == StreakVisualState.normal &&
        _isAtRiskNow()) {
      _machine.onAtRisk();
    }

    _scheduleAtRiskTimer();
    _scheduleMidnightTimer();

    final changed =
        prevState != _machine.state ||
        prevStreak != _machine.streakDays ||
        prevFreeze != _machine.freezeCount;
    if (changed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final freeze = context.watch<StreakFreezeProvider>();

    // Keep counts in sync even when only build triggers.
    _machine.syncCounts(streakDays: progress.streak, freezeCount: freeze.count);

    final onTap = widget.onTap ?? () => StreakFreezeShopSheet.show(context);

    return AnimatedStreakBadge(
      streakDays: progress.streak,
      freezeCount: freeze.count,
      state: _machine.state,
      onTap: onTap,
      playProtectedOnce: true,
    );
  }
}
