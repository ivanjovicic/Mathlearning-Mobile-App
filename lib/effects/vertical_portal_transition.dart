import 'dart:ui';
import 'package:flutter/material.dart';

class VerticalPortalTransition extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;

  const VerticalPortalTransition({
    super.key,
    required this.child,
    required this.trigger,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  State<VerticalPortalTransition> createState() =>
      _VerticalPortalTransitionState();
}

class _VerticalPortalTransitionState extends State<VerticalPortalTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didUpdateWidget(covariant VerticalPortalTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When not animating, just show the child directly – no portal overlays.
    if (!_controller.isAnimating) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = _controller.value;
        final portalOpen = Curves.easeOutCubic.transform(t);
        final fadeInNew = Curves.easeIn.transform((t - 0.3).clamp(0, 1));
        final glowOpacity = (t * 2).clamp(0, 1);

        return Stack(
          alignment: Alignment.topLeft,
          children: [
            // New UI (appears gradually)
            Opacity(opacity: fadeInNew, child: widget.child),

            // Vertical split panels (old UI)
            ClipPath(
              clipper: _LeftHalfPortalClip(portalOpen),
              child: Container(
                color: Colors.black,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                ),
              ),
            ),
            ClipPath(
              clipper: _RightHalfPortalClip(portalOpen),
              child: Container(color: Colors.black),
            ),

            // Portal glow
            Opacity(
              opacity: glowOpacity * 0.8,
              child: Center(
                child: Container(
                  width: (portalOpen * 250),
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(0),
                        Colors.white.withAlpha((0.6 * 255).round()),
                        Colors.white.withAlpha(0),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),

            // Optional: blur center for magical effect
            if (portalOpen > 0.2)
              Center(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: portalOpen * 8,
                    sigmaY: portalOpen * 8,
                  ),
                  child: Container(
                    width: portalOpen * 200,
                    height: double.infinity,
                    color: Colors.white.withAlpha((0.02 * 255).round()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// LEFT PANEL CLIPPER
class _LeftHalfPortalClip extends CustomClipper<Path> {
  final double open;

  _LeftHalfPortalClip(this.open);

  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(0, 0);
    p.lineTo(size.width * (0.5 - open * 0.5), 0);
    p.lineTo(size.width * (0.5 - open * 0.5), size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_) => true;
}

/// RIGHT PANEL CLIPPER
class _RightHalfPortalClip extends CustomClipper<Path> {
  final double open;

  _RightHalfPortalClip(this.open);

  @override
  Path getClip(Size size) {
    final p = Path();
    p.moveTo(size.width * (0.5 + open * 0.5), 0);
    p.lineTo(size.width, 0);
    p.lineTo(size.width, size.height);
    p.lineTo(size.width * (0.5 + open * 0.5), size.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(_) => true;
}
