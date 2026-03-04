import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyStreakWidget extends StatefulWidget {
  final int streak;
  final int xpEarnedToday;

  const DailyStreakWidget({
    super.key,
    required this.streak,
    this.xpEarnedToday = 0,
  });

  @override
  State<DailyStreakWidget> createState() => _DailyStreakWidgetState();
}

class _DailyStreakWidgetState extends State<DailyStreakWidget>
    with TickerProviderStateMixin {
  bool showXpBurst = false;
  int _lastXp = 0;

  @override
  void initState() {
    super.initState();
    _lastXp = widget.xpEarnedToday;
  }

  @override
  void didUpdateWidget(covariant DailyStreakWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // trigger XP burst only when XP grows
    if (widget.xpEarnedToday > oldWidget.xpEarnedToday) {
      triggerXpAnimation();
    }
  }

  void triggerXpAnimation() {
    setState(() => showXpBurst = true);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => showXpBurst = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final streak = widget.streak;

    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // -----------------------------
          // FIRE ICON (animated)
          // -----------------------------
          Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade200.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade300.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_fire_department,
                  size: 48,
                  color: Colors.orange.shade600,
                ),
              )
              .animate(key: ValueKey(streak))
              .scale(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
              )
              .shimmer(duration: 1200.ms, color: Colors.orangeAccent),

          // -----------------------------
          // STREAK NUMBER
          // -----------------------------
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.shade400, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.whatshot, size: 16, color: Colors.orange.shade400),
                  const SizedBox(width: 4),
                  Text(
                    "$streak dana",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
          ),

          // -----------------------------
          // XP BURST ANIMATION
          // -----------------------------
          if (showXpBurst)
            Positioned(
              top: 8,
              child:
                  Text(
                        "+${widget.xpEarnedToday - _lastXp} XP",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow.shade600,
                          shadows: const [
                            Shadow(blurRadius: 12, color: Colors.orange),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .move(
                        duration: 800.ms,
                        begin: const Offset(0, 20),
                        end: const Offset(0, -35),
                      )
                      .fadeOut(delay: 400.ms),
            ),

          // -----------------------------
          // FIREWORK PARTICLES
          // -----------------------------
          if (showXpBurst)
            ...List.generate(8, (index) {
              return Positioned(
                top: 50,
                left: 50,
                child:
                    Transform.translate(
                          offset: Offset(
                            30 * (index % 2 == 0 ? 1 : -1),
                            30 * (index ~/ 2 % 2 == 0 ? 1 : -1),
                          ),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index % 2 == 0
                                  ? Colors.yellow.shade400
                                  : Colors.orange.shade400,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 100.ms)
                        .scale(
                          duration: 600.ms,
                          begin: const Offset(0, 0),
                          end: const Offset(2, 2),
                        )
                        .fadeOut(delay: 300.ms),
              );
            }),
        ],
      ),
    );
  }
}
