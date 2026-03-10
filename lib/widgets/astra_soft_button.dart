import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AI-minimal neumorphic button — smooth dark raised/flush surface
/// with subtle light/shadow edges, press animation, and haptic feedback.
class AstraSoftButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? accentColor;
  final bool enabled;
  final double? width;

  const AstraSoftButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.accentColor,
    this.enabled = true,
    this.width,
  });

  @override
  State<AstraSoftButton> createState() => _AstraSoftButtonState();
}

class _AstraSoftButtonState extends State<AstraSoftButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final cs = Theme.of(context).colorScheme;
    final effectiveAccent = widget.accentColor ?? cs.primary;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final opacity = widget.enabled ? 1.0 : 0.4;

    // Neumorphic shadows shift when pressed to appear "flush"
    final darkShadow = BoxShadow(
      color: Colors.black.withValues(alpha: _pressed ? 0.5 : 0.7),
      blurRadius: _pressed ? 6 : 12,
      offset: _pressed ? const Offset(2, 2) : const Offset(4, 4),
    );
    final lightShadow = BoxShadow(
      color: Colors.white.withValues(alpha: _pressed ? 0.02 : 0.05),
      blurRadius: _pressed ? 6 : 12,
      offset: _pressed ? const Offset(-2, -2) : const Offset(-4, -4),
    );

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
      decoration: BoxDecoration(
        color: _pressed
            ? cs.surfaceContainerHighest.withValues(alpha: 0.85)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _pressed
              ? effectiveAccent.withValues(alpha: 0.25)
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: [darkShadow, lightShadow],
      ),
      child: Row(
        mainAxisSize:
            widget.width != null ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: effectiveAccent, size: 20),
            const SizedBox(width: 10),
          ],
          Text(
            widget.text,
            style: const TextStyle(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
