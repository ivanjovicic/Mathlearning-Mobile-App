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

  @override
  void initState() {
    super.initState();
    final newProgress = widget.maxXp == 0
        ? 0.0
        : widget.currentXp / widget.maxXp;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = Tween<double>(
      begin: 0.0,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedXpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgress = widget.maxXp == 0
        ? 0.0
        : widget.currentXp / widget.maxXp;
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: newProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final instantValue = widget.maxXp == 0
        ? 0.0
        : widget.currentXp / widget.maxXp;
    if (reduceMotion) {
      final value = instantValue.clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${(value * widget.maxXp).toInt()} / ${widget.maxXp} XP",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                          colorScheme.secondary,
                          colorScheme.primary,
                          colorScheme.tertiary,
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
    }
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, child) {
        final value = _progressAnim.value.clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${(value * widget.maxXp).toInt()} / ${widget.maxXp} XP",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                            colorScheme.secondary,
                            colorScheme.primary,
                            colorScheme.tertiary,
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
