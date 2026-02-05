import 'package:flutter/material.dart';

class GameButton extends StatefulWidget {
  final String text;
  final Widget? child;
  final bool disabled;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const GameButton({
    super.key,
    required this.text,
    required this.onTap,
    this.child,
    this.disabled = false,
    this.isCorrect = false,
    this.isWrong = false,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    late final Color bgColor;
    late final Color fgColor;

    if (widget.isCorrect) {
      bgColor = colorScheme.tertiary;
      fgColor = colorScheme.onTertiary;
    } else if (widget.isWrong) {
      bgColor = colorScheme.error;
      fgColor = colorScheme.onError;
    } else {
      bgColor = colorScheme.primary;
      fgColor = colorScheme.onPrimary;
    }

    return AnimatedScale(
      scale: _scale,
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.disabled ? null : widget.onTap,
          onHighlightChanged: reduceMotion
              ? null
              : (isHighlighted) {
                  setState(() {
                    _scale = isHighlighted ? 0.95 : 1.0;
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  bgColor.withValues(alpha: 0.9),
                  bgColor.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child:
                  widget.child ??
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: fgColor,
                      letterSpacing: 1.2,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
