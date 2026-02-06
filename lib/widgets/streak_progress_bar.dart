import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StreakProgressBar extends StatefulWidget {
  final int streak; // e.g. 7
  final int maxStreak; // e.g. 30
  final double height;
  final bool enableBurst;

  const StreakProgressBar({
    super.key,
    required this.streak,
    this.maxStreak = 30,
    this.height = 22,
    this.enableBurst = false,
  });

  @override
  State<StreakProgressBar> createState() => _StreakProgressBarState();
}

class _StreakProgressBarState extends State<StreakProgressBar> {
  bool _showBurst = false;

  @override
  void didUpdateWidget(covariant StreakProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enableBurst && widget.streak > oldWidget.streak) {
      _triggerBurst();
    }
  }

  void _triggerBurst() {
    setState(() => _showBurst = true);

    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _showBurst = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.streak / widget.maxStreak).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              "${widget.streak}-day streak",
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.orange.shade300,
                  )
                ],
              ),
            )
          ],
        ).animate().fadeIn().scale(duration: 300.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 10),
        SizedBox(
          height: widget.height + 24,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade900,
                ),
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth * progress;

                        return AnimatedContainer(
                          duration: 700.ms,
                          curve: Curves.easeOutCubic,
                          width: width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade400,
                                Colors.orange.shade700,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    Center(
                      child: Text(
                        "${widget.streak} / ${widget.maxStreak}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showBurst)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _BurstOverlay(
                      key: ValueKey(widget.streak),
                    ),
                  ),
                ),
            ],
          ),
        )
            .animate(
              key: ValueKey(widget.streak),
            )
            .scale(
              duration: 300.ms,
              curve: Curves.easeOutBack,
            )
            .then()
            .shimmer(
              duration: 1200.ms,
              color: Colors.orangeAccent,
            ),
      ],
    );
  }
}

class _BurstOverlay extends StatelessWidget {
  const _BurstOverlay({super.key});

  static const _offsets = [
    Offset(-40, -18),
    Offset(-14, -32),
    Offset(14, -34),
    Offset(40, -14),
    Offset(-26, 8),
    Offset(28, 10),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: _offsets.map((offset) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.yellow.shade400,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.6),
                blurRadius: 8,
              ),
            ],
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.1, 1.1),
              duration: 220.ms,
              curve: Curves.easeOut,
            )
            .move(
              begin: Offset.zero,
              end: offset,
              duration: 520.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeOut(
              delay: 120.ms,
              duration: 420.ms,
            );
      }).toList(),
    );
  }
}
