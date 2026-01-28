import 'package:flutter/material.dart';

class GameButton extends StatefulWidget {
  final String text;
  final bool disabled;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const GameButton({
    super.key,
    required this.text,
    required this.onTap,
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
    Color bgColor;

    if (widget.isCorrect) {
      bgColor = Colors.greenAccent.shade400;
    } else if (widget.isWrong) {
      bgColor = Colors.redAccent.shade200;
    } else {
      bgColor = Colors.blue.shade500;
    }

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.95),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTapUp: (_) => setState(() {
          _scale = 1.0;
          if (!widget.disabled) widget.onTap();
        }),
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
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
