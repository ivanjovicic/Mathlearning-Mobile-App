import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/astrax_theme.dart';

/// Premium glassmorphism button with frosted backdrop, neon border glow,
/// press-scale animation, and haptic feedback.
class AstraGlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color glowColor;
  final bool enabled;
  final double? width;

  const AstraGlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.glowColor = AstraXTheme.neonBlue,
    this.enabled = true,
    this.width,
  });

  @override
  State<AstraGlassButton> createState() => _AstraGlassButtonState();
}

class _AstraGlassButtonState extends State<AstraGlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    _ctrl.forward();
  }

  void _onTapUp(_) {
    if (!widget.enabled) return;
    setState(() => _pressed = false);
    _ctrl.reverse();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    setState(() => _pressed = false);
    _ctrl.reverse();
  }

  void _onTap() {
    if (!widget.enabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final glow = widget.glowColor;
    final opacity = widget.enabled ? 1.0 : 0.45;

    Widget button = ClipRRect(
      borderRadius: BorderRadius.circular(AstraXTheme.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          decoration: BoxDecoration(
            color: _pressed
                ? AstraXTheme.glass.withValues(alpha: 0.5)
                : AstraXTheme.glass.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AstraXTheme.radius),
            border: Border.all(
              color: glow.withValues(alpha: _pressed ? 0.8 : 0.5),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: _pressed ? 0.45 : 0.25),
                blurRadius: _pressed ? 28 : 20,
                spreadRadius: -2,
              ),
              // Inner glow hint
              BoxShadow(
                color: glow.withValues(alpha: 0.08),
                blurRadius: 60,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: widget.width != null
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: opacity),
                  fontSize: 18,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      button = ScaleTransition(scale: _scaleAnim, child: button);
    }

    return SizedBox(
      width: widget.width,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.text,
        child: GestureDetector(
          onTap: _onTap,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Opacity(opacity: opacity, child: button),
        ),
      ),
    );
  }
}
