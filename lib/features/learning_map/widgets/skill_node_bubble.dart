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
  });

  final SkillNode node;
  final SkillNodeState state;
  final double progress;
  final VoidCallback onTap;
  final String semanticLabel;
  final bool showNextLabel;

  @override
  State<SkillNodeBubble> createState() => _SkillNodeBubbleState();
}

class _SkillNodeBubbleState extends State<SkillNodeBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _unlockTimer;
  bool _unlockPulse = false;

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
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _colorsForState(theme.colorScheme, widget.state);
    final spacing = context.spacing;
    final motion = context.motion;
    final progress = widget.progress.clamp(0.0, 1.0);
    final isLocked = widget.state == SkillNodeState.locked;
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
          if (widget.state == SkillNodeState.recommended)
            BoxShadow(
              color: colors.glow.withValues(alpha: 0.45),
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
        alignment: Alignment.center,
        children: [
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
                isLocked ? Icons.lock_outline_rounded : icon,
                color: colors.foreground,
                size: AppScale.icon(24, min: 20, max: 30),
              ),
              SizedBox(height: spacing.xs),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (widget.state == SkillNodeState.mastered)
            Positioned(
              right: AppScale.s(14),
              top: AppScale.s(14),
              child: Icon(
                Icons.check_circle,
                color: context.learningTheme.masteryStrong,
                size: AppScale.icon(20, min: 18, max: 24),
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
                  scale: _unlockPulse ? 1.08 : 1.0,
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
                if (widget.showNextLabel) ...[
                  SizedBox(height: spacing.xs),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.s + spacing.xs / 2,
                      vertical: spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(context.radius.pill),
                    ),
                    child: Text(
                      'Next',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
        background: colors.secondaryContainer,
        foreground: colors.onSecondaryContainer,
        border: colors.secondary,
        progress: colors.secondary,
        progressBackground: colors.secondaryContainer.withValues(alpha: 0.35),
        glow: colors.secondary,
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
