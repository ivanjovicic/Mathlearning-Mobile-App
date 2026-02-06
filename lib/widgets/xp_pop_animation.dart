import 'package:flutter/material.dart';

class XpPopAnimation extends StatefulWidget {
  final int xp;
  final String? label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final bool reduceMotion;

  const XpPopAnimation({
    super.key,
    required this.xp,
    this.label,
    this.backgroundColor = Colors.yellowAccent,
    this.textColor = Colors.black,
    this.icon,
    this.reduceMotion = false,
  });

  @override
  State<XpPopAnimation> createState() => _XpPopAnimationState();
}

class _XpPopAnimationState extends State<XpPopAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration:
          widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
    );

    _scale = Tween<double>(begin: 0.2, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label ?? "+${widget.xp} XP";
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.textColor, size: 20),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
