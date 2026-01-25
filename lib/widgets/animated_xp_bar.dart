import 'package:flutter/material.dart';

class AnimatedXpBar extends StatefulWidget {
  final int currentXp;
  final int maxXp;

  const AnimatedXpBar({
    super.key,
    required this.currentXp,
    required this.maxXp,
  });

  @override
  State<AnimatedXpBar> createState() => _AnimatedXpBarState();
}

class _AnimatedXpBarState extends State<AnimatedXpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;

  double oldProgress = 0;

  @override
  void initState() {
    super.initState();

    double newProgress = widget.currentXp / widget.maxXp;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _progressAnim = Tween<double>(
      begin: 0,
      end: newProgress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedXpBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // kada se XP promeni → animiraj ponovo
    double newProgress = widget.currentXp / widget.maxXp;

    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: newProgress,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, child) {
        double value = _progressAnim.value.clamp(0, 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // XP tekst
            Text(
              "${(value * widget.maxXp).toInt()} / ${widget.maxXp} XP",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            // XP bar
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            Colors.yellow.shade400,
                            Colors.orange.shade400,
                            Colors.red.shade400,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
