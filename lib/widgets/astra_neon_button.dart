import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/astrax_theme.dart';

/// Cyberpunk-style neon gradient button with outer glow, press animation,
/// and optional shimmer streak effect.
class AstraNeonButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final List<Color>? gradientColors;
  final bool enabled;
  final double? width;

  const AstraNeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.gradientColors,
    this.enabled = true,
    this.width,
  });

  @override
  State<AstraNeonButton> createState() => _AstraNeonButtonState();
}

class _AstraNeonButtonState extends State<AstraNeonButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;
  late final AnimationController _shimmerCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (!widget.enabled) return;
    setState(() => _pressed = true);
    _pressCtrl.forward();
  }

  void _onTapUp(_) {
    if (!widget.enabled) return;
    setState(() => _pressed = false);
    _pressCtrl.reverse();
  }

  void _onTapCancel() {
    if (!widget.enabled) return;
    setState(() => _pressed = false);
    _pressCtrl.reverse();
  }

  void _onTap() {
    if (!widget.enabled) return;
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final colors = widget.gradientColors ??
        [
          AstraXTheme.neonPurple.withValues(alpha: 0.9),
          AstraXTheme.neonBlue.withValues(alpha: 0.9),
        ];
    final glowColor =
        widget.gradientColors?.first ?? AstraXTheme.neonPurple;
    final opacity = widget.enabled ? 1.0 : 0.4;

    Widget button = AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AstraXTheme.radius),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: _pressed ? 0.65 : 0.4),
                blurRadius: _pressed ? 34 : 24,
              ),
              // Subtle secondary glow
              BoxShadow(
                color: colors.last.withValues(alpha: 0.15),
                blurRadius: 50,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Shimmer streak
              if (!reduceMotion)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AstraXTheme.radius),
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        final pos = _shimmerCtrl.value * 2 - 0.5;
                        return LinearGradient(
                          begin: Alignment(pos - 0.3, -0.5),
                          end: Alignment(pos + 0.3, 0.5),
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.srcATop,
                      child: Container(color: Colors.white),
                    ),
                  ),
                ),
              Row(
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
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

