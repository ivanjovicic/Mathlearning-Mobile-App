import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/theme/app_scale.dart';
import 'package:mathlearning/theme/theme_extensions/theme_context.dart';
import 'package:mathlearning/widgets/ui/app_card.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({
    super.key,
    required this.streakDays,
    required this.practicedToday,
  });

  final int streakDays;

  /// True when the user has already completed a practice session today.
  final bool practicedToday;

  bool get _isAtRisk => streakDays > 0 && !practicedToday;
  bool get _isNew => streakDays == 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final spacing = context.spacing;

    final Color background;
    final Color iconColor;
    final Color borderColor;
    final IconData icon;
    final String headline;
    final String subline;

    if (_isNew) {
      background = cs.primaryContainer.withValues(alpha: 0.45);
      iconColor = cs.primary;
      borderColor = cs.primary.withValues(alpha: 0.25);
      icon = Icons.local_fire_department_rounded;
      headline = 'Start your streak today!';
      subline = 'Practice every day and watch your streak grow! 🔥';
    } else if (_isAtRisk) {
      background = cs.errorContainer.withValues(alpha: 0.40);
      iconColor = cs.error;
      borderColor = cs.error.withValues(alpha: 0.30);
      icon = Icons.local_fire_department_rounded;
      headline = 'Don\'t lose your streak!';
      subline = 'One practice today saves your $streakDays-day streak!';
    } else {
      background = const Color(0xFFFF6B00).withValues(alpha: 0.12);
      iconColor = const Color(0xFFFF6B00);
      borderColor = const Color(0xFFFF6B00).withValues(alpha: 0.25);
      icon = Icons.local_fire_department_rounded;
      headline = '$streakDays-Day Streak! 🔥';
      subline = _encouragement(streakDays);
    }

    final card = AppCard(
      backgroundColor: background,
      borderColor: borderColor,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.m,
        vertical: spacing.s + spacing.xs,
      ),
      child: Row(
        children: [
          _StreakFlameIcon(
            icon: icon,
            color: iconColor,
            streakDays: streakDays,
            atRisk: _isAtRisk,
          ),
          SizedBox(width: spacing.s + spacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _isAtRisk
                        ? cs.error
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: spacing.xs / 2),
                Text(
                  subline,
                  style: tt.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (_isAtRisk) {
      return card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1800.ms, color: cs.error.withValues(alpha: 0.08));
    }

    return card;
  }

  static String _encouragement(int days) {
    if (days >= 30) return 'A whole month! You\'re unstoppable! 🏆';
    if (days >= 14) return 'Two whole weeks! 🏆 You\'re a streak machine!';
    if (days >= 7) return 'One full week in a row! 🎉 You\'re unstoppable!';
    if (days >= 3) return 'Keep the fire alive — you\'re on a streak! 🔥';
    return 'Off to a great start — come back tomorrow! 🌟';
  }
}

class _StreakFlameIcon extends StatelessWidget {
  const _StreakFlameIcon({
    required this.icon,
    required this.color,
    required this.streakDays,
    required this.atRisk,
  });

  final IconData icon;
  final Color color;
  final int streakDays;
  final bool atRisk;

  @override
  Widget build(BuildContext context) {
    final tierBoost = streakDays >= 30
        ? 10.0
        : streakDays >= 14
        ? 7.0
        : streakDays >= 7
        ? 4.0
        : 0.0;
    final size = AppScale.icon(32 + tierBoost, min: 28, max: 48);
    return Container(
      key: const Key('streak_evolved_flame'),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: atRisk ? 0.16 : 0.12),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: streakDays >= 7 ? 0.28 : 0.12),
            blurRadius: streakDays >= 14 ? 18 : 10,
            spreadRadius: streakDays >= 30 ? 2 : 0,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}
