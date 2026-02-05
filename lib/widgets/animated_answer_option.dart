import 'package:flutter/material.dart';

class AnimatedAnswerOption extends StatefulWidget {
  final String text;
  final bool isEliminated;
  final bool isSelected;
  final VoidCallback? onTap;
  final Duration animationDuration;

  const AnimatedAnswerOption({
    super.key,
    required this.text,
    this.isEliminated = false,
    this.isSelected = false,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedAnswerOption> createState() => _AnimatedAnswerOptionState();
}

class _AnimatedAnswerOptionState extends State<AnimatedAnswerOption>
    with TickerProviderStateMixin {
  late AnimationController _eliminateController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _eliminateController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _eliminateController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _eliminateController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedAnswerOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isEliminated != oldWidget.isEliminated) {
      if (widget.isEliminated) {
        _eliminateController.forward();
      } else {
        _eliminateController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _eliminateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      final bg = widget.isSelected
          ? colorScheme.primaryContainer
          : widget.isEliminated
          ? colorScheme.surfaceContainerHighest
          : colorScheme.surface;
      final border = widget.isSelected
          ? colorScheme.primary
          : widget.isEliminated
          ? colorScheme.outline
          : colorScheme.outlineVariant;
      final textColor = widget.isEliminated
          ? colorScheme.onSurface
          : widget.isSelected
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurface;
      return Opacity(
        opacity: widget.isEliminated ? 0.2 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.isEliminated ? null : widget.onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(
                  color: border,
                  width: widget.isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  if (widget.isEliminated)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          height: 2,
                          color: colorScheme.error.withValues(alpha: 0.6),
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
    return AnimatedBuilder(
      animation: _eliminateController,
      builder: (context, child) {
        final bg = widget.isSelected
            ? colorScheme.primaryContainer
            : widget.isEliminated
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface;
        final border = widget.isSelected
            ? colorScheme.primary
            : widget.isEliminated
            ? colorScheme.outline
            : colorScheme.outlineVariant;
        final textColor = widget.isEliminated
            ? colorScheme.onSurface
            : widget.isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface;

        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.isEliminated ? null : widget.onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: bg,
                    border: Border.all(
                      color: border,
                      width: widget.isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: widget.isEliminated
                        ? const []
                        : [
                            BoxShadow(
                              color: colorScheme.scrim.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Stack(
                    children: [
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      if (widget.isEliminated)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              height: 2,
                              color: colorScheme.error.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
