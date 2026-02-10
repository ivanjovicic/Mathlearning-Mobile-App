import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/astrax_theme.dart';

class DailyStreakBadge extends StatefulWidget {
  final int currentStreak;
  final int bestStreak;
  final bool isTodayCompleted;
  final VoidCallback? onTap;
  final double height;

  const DailyStreakBadge({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.isTodayCompleted,
    this.onTap,
    this.height = 88,
  });

  @override
  State<DailyStreakBadge> createState() => _DailyStreakBadgeState();
}

class _DailyStreakBadgeState extends State<DailyStreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _mainColor => widget.isTodayCompleted
      ? AstraXTheme.neonGreen
      : const Color(0xFFFFC857);

  Color get _flameColor => widget.isTodayCompleted
      ? const Color(0xFFFFF6E6)
      : const Color(0xFFFFE0B2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            height: widget.height,
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AstraXTheme.bg.withValues(alpha: 0.94),
                  AstraXTheme.panelLight.withValues(alpha: 0.98),
                ],
              ),
              border: Border.all(
                width: 1.4,
                color: _mainColor.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: _mainColor.withValues(alpha: 0.26 * _glowAnim.value),
                  blurRadius: 18 + 10 * _glowAnim.value,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -10,
                  child: Transform.rotate(
                    angle: math.pi / 12,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _mainColor.withValues(alpha: 0.16 * _glowAnim.value),
                            bgColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -40,
                  bottom: -10,
                  child: Transform.rotate(
                    angle: -math.pi / 10,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AstraXTheme.neonPurple.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                _mainColor.withValues(alpha: 0.12),
                                _mainColor.withValues(alpha: 0.35),
                              ],
                            ),
                            border: Border.all(
                              width: 1.2,
                              color: _mainColor.withValues(alpha: 0.8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _mainColor.withValues(
                                  alpha: 0.4 + 0.3 * _glowAnim.value,
                                ),
                                blurRadius: 16 + 6 * _glowAnim.value,
                                spreadRadius: 1.5,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              size: 26,
                              color: _flameColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Daily Streak',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: widget.isTodayCompleted
                                              ? AstraXTheme.neonGreen
                                              : const Color(0xFFFFC857),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.isTodayCompleted
                                            ? 'Today done'
                                            : "Don't break it",
                                        style:
                                            theme.textTheme.labelSmall?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${widget.currentStreak} days',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: _mainColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'current streak',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final pct =
                                    (widget.currentStreak / 30).clamp(0.0, 1.0);
                                return Container(
                                  width: constraints.maxWidth,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 600),
                                        width: constraints.maxWidth * pct,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: [
                                              _mainColor.withValues(alpha: 0.8),
                                              _mainColor.withValues(alpha: 0.4),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _mainColor.withValues(
                                                alpha: 0.35,
                                              ),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 20,
                            color: Colors.amberAccent.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Best',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${widget.bestStreak}d',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
