import 'dart:async';

import 'package:flutter/material.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/skill_node_state.dart';
import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';
import 'package:mathlearning/theme/tokens/app_motion.dart';

class SkillNodeBubble extends StatefulWidget {
  const SkillNodeBubble({
    super.key,
    required this.node,
    required this.state,
    required this.progress,
    required this.onTap,
    required this.semanticLabel,
    this.showNextLabel = false,
    this.showCompletionFeedback = false,
    this.completionXp,
  });

  final SkillNode node;
  final SkillNodeState state;
  final double progress;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool showNextLabel;
  final bool showCompletionFeedback;
  final int? completionXp;

  @override
  State<SkillNodeBubble> createState() => _SkillNodeBubbleState();
}

class _SkillNodeBubbleState extends State<SkillNodeBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _unlockTimer;
  Timer? _celebrationTimer;
  Timer? _celebrationPulseTimer;
  bool _unlockPulse = false;
  bool _celebrationPulse = false;
  bool _showCompletionBadge = false;
  bool _showFloatingXp = false;
  bool _showLevelCompleteLabel = false;
  int _celebrationRun = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _progressController, curve: AppMotion.standard),
    );
    _progressController.forward();
    _maybeStartCompletionFeedback();
  }

  @override
  void didUpdateWidget(covariant SkillNodeBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: AppMotion.standard,
            ),
          );
      _progressController
        ..reset()
        ..forward();
    }

    if (oldWidget.state == SkillNodeState.locked &&
        widget.state != SkillNodeState.locked) {
      setState(() => _unlockPulse = true);
      _unlockTimer?.cancel();
      _unlockTimer = Timer(
        AppMotion.slow,
        () => mounted ? setState(() => _unlockPulse = false) : null,
      );
    }

    if (oldWidget.showCompletionFeedback != widget.showCompletionFeedback ||
        oldWidget.completionXp != widget.completionXp) {
      _maybeStartCompletionFeedback();
    }
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    _celebrationTimer?.cancel();
    _celebrationPulseTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final motion = context.motion;
    final progress = widget.progress.clamp(0.0, 1.0);
    final isLocked = widget.state == SkillNodeState.locked;
    final isCompleted = progress >= 0.999;
    final visualState = isLocked
        ? SkillNodeState.locked
        : isCompleted
        ? SkillNodeState.mastered
        : widget.state == SkillNodeState.mastered
        ? SkillNodeState.learning
        : widget.state;
    final colors = _colorsForState(theme.colorScheme, visualState);
    final icon = _iconForTitle(widget.node.title);

    final bubble = AnimatedContainer(
      duration: motion.fast,
      curve: motion.decelerate,
      width: AppScale.s(112),
      height: AppScale.s(112),
      decoration: BoxDecoration(
        color: colors.background,
        shape: BoxShape.circle,
        boxShadow: [
          if (!isLocked)
            BoxShadow(
              color: colors.glow.withValues(
                alpha: _showCompletionBadge
                    ? 0.42
                    : visualState == SkillNodeState.recommended
                    ? 0.45
                    : isCompleted
                    ? 0.22
                    : 0.18,
              ),
              blurRadius: AppScale.s(18),
              spreadRadius: AppScale.s(1.5),
            ),
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: AppScale.s(10),
            offset: Offset(0, AppScale.s(4)),
          ),
        ],
        border: Border.all(color: colors.border, width: AppScale.s(2)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_showLevelCompleteLabel)
            Positioned(
              top: -AppScale.s(18),
              left: 0,
              right: 0,
              child: _CelebrationPill(
                key: ValueKey('level_complete_$_celebrationRun'),
                label: 'Level Complete!',
                backgroundColor: colors.background,
                foregroundColor: colors.foreground,
                borderColor: colors.border,
                riseDistance: AppScale.s(14),
              ),
            ),
          if (_showFloatingXp && widget.completionXp != null)
            Positioned(
              top: -AppScale.s(8),
              right: -AppScale.s(10),
              child: _CelebrationPill(
                key: ValueKey('xp_feedback_$_celebrationRun'),
                label: '+${widget.completionXp} XP',
                backgroundColor: colors.background,
                foregroundColor: colors.foreground,
                borderColor: colors.border,
                riseDistance: AppScale.s(20),
              ),
            ),
          SizedBox(
            width: AppScale.s(96),
            height: AppScale.s(96),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, _) {
                return CircularProgressIndicator(
                  value: isLocked ? 0 : _progressAnimation.value,
                  strokeWidth: AppScale.s(5),
                  color: colors.progress,
                  backgroundColor: colors.progressBackground,
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLocked
                    ? Icons.lock_outline_rounded
                    : isCompleted
                    ? Icons.check_rounded
                    : icon,
                color: colors.foreground,
                size: AppScale.icon(24, min: 20, max: 30),
              ),
              SizedBox(height: spacing.xs),
              Text(
                _centerLabel(progress, isLocked: isLocked, isCompleted: isCompleted),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (isCompleted || _showCompletionBadge)
            Positioned(
              right: AppScale.s(14),
              top: AppScale.s(14),
              child: AnimatedScale(
                scale: _showCompletionBadge ? 1.12 : 1.0,
                duration: motion.fast,
                curve: motion.decelerate,
                child: Icon(
                  Icons.check_circle,
                  color: isCompleted ? colors.foreground : colors.progress,
                  size: AppScale.icon(20, min: 18, max: 24),
                ),
              ),
            ),
        ],
      ),
    );

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        child: InkWell(
          key: Key('skill_node_${widget.node.id}'),
          borderRadius: BorderRadius.circular(AppScale.radius(72)),
          onTap: widget.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: spacing.s,
              horizontal: spacing.xs + spacing.xs / 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  duration: motion.fast,
                  scale: _unlockPulse || _celebrationPulse ? 1.08 : 1.0,
                  child: bubble,
                ),
                SizedBox(height: spacing.s),
                SizedBox(
                  width: AppScale.s(150),
                  child: Text(
                    widget.node.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: spacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.s + spacing.xs / 2,
                    vertical: spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _badgeBackgroundColor(theme.colorScheme, isLocked, isCompleted),
                    borderRadius: BorderRadius.circular(context.radius.pill),
                  ),
                  child: Text(
                    _badgeLabel(isLocked: isLocked, isCompleted: isCompleted),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _badgeForegroundColor(theme.colorScheme, isLocked, isCompleted),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _maybeStartCompletionFeedback() {
    if (!widget.showCompletionFeedback) {
      return;
    }

    _celebrationTimer?.cancel();
    _celebrationPulseTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _celebrationRun += 1;
      _celebrationPulse = true;
      _showCompletionBadge = true;
      _showFloatingXp = (widget.completionXp ?? 0) > 0;
      _showLevelCompleteLabel = true;
    });

    _celebrationPulseTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() => _celebrationPulse = false);
    });

    _celebrationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showCompletionBadge = false;
        _showFloatingXp = false;
        _showLevelCompleteLabel = false;
      });
    });
  }

  String _centerLabel(double progress, {required bool isLocked, required bool isCompleted}) {
    if (isLocked) {
      return 'Locked';
    }
    if (isCompleted) {
      return 'DONE';
    }
    return 'Level ${_levelNumber(progress)}';
  }

  int _levelNumber(double progress) {
    if (progress >= 0.67) return 3;
    if (progress >= 0.34) return 2;
    return 1;
  }

  String _badgeLabel({required bool isLocked, required bool isCompleted}) {
    if (isLocked) {
      return 'Locked';
    }
    if (isCompleted) {
      return 'DONE';
    }
    return 'Play';
  }

  Color _badgeBackgroundColor(
    ColorScheme colorScheme,
    bool isLocked,
    bool isCompleted,
  ) {
    if (isLocked) {
      return colorScheme.surfaceContainerHighest;
    }
    if (isCompleted) {
      return const Color(0xFFFFF1BF);
    }
    return widget.showNextLabel
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;
  }

  Color _badgeForegroundColor(
    ColorScheme colorScheme,
    bool isLocked,
    bool isCompleted,
  ) {
    if (isLocked) {
      return colorScheme.onSurfaceVariant;
    }
    if (isCompleted) {
      return const Color(0xFF8A5B00);
    }
    return widget.showNextLabel
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;
  }

  IconData _iconForTitle(String title) {
    final value = title.toLowerCase();
    if (value.contains('fraction')) return Icons.pie_chart_outline_rounded;
    if (value.contains('equation')) return Icons.functions_rounded;
    if (value.contains('geometry')) return Icons.change_history_rounded;
    if (value.contains('algebra')) return Icons.auto_graph_rounded;
    return Icons.school_rounded;
  }
}

class _CelebrationPill extends StatelessWidget {
  const _CelebrationPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.riseDistance,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double riseDistance;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -riseDistance * value),
            child: child,
          ),
        );
      },
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppScale.s(10),
            vertical: AppScale.s(6),
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(AppScale.radius(999)),
            border: Border.all(color: borderColor.withValues(alpha: 0.95)),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.18),
                blurRadius: AppScale.s(12),
                offset: Offset(0, AppScale.s(4)),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeColors {
  const _NodeColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.progress,
    required this.progressBackground,
    required this.glow,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color progress;
  final Color progressBackground;
  final Color glow;
}

_NodeColors _colorsForState(ColorScheme colors, SkillNodeState state) {
  switch (state) {
    case SkillNodeState.locked:
      return _NodeColors(
        background: colors.surfaceContainerHighest,
        foreground: colors.onSurfaceVariant,
        border: colors.outlineVariant,
        progress: colors.outline,
        progressBackground: colors.surfaceContainerLow,
        glow: colors.outline,
      );
    case SkillNodeState.mastered:
      return _NodeColors(
        background: const Color(0xFFFFF8DD),
        foreground: const Color(0xFF8A5B00),
        border: const Color(0xFFE0B200),
        progress: const Color(0xFFE0B200),
        progressBackground: const Color(0xFFFFF1BF),
        glow: const Color(0xFFE0B200),
      );
    case SkillNodeState.recommended:
      return _NodeColors(
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
        border: colors.primary,
        progress: colors.primary,
        progressBackground: colors.primaryContainer.withValues(alpha: 0.35),
        glow: colors.primary,
      );
    case SkillNodeState.learning:
      return _NodeColors(
        background: colors.surfaceContainerLow,
        foreground: colors.onSurface,
        border: colors.primary.withValues(alpha: 0.5),
        progress: colors.primary,
        progressBackground: colors.surfaceContainerHighest,
        glow: colors.primary,
      );
  }
}
