import 'package:flutter/material.dart';
import 'xp_pop_animation.dart';

/// Thin wrapper around [XpPopAnimation] that pulls reduced-motion state
/// from [MediaQuery] automatically.
///
/// Drop this into any screen that needs to celebrate an XP gain.
class XPAnimation extends StatelessWidget {
  final int xp;
  final String? label;

  const XPAnimation({super.key, required this.xp, this.label});

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.of(context).disableAnimations;

    return XpPopAnimation(
      xp: xp,
      label: label ?? '+$xp XP',
      backgroundColor: const Color(0xFF6C63FF),
      textColor: Colors.white,
      icon: Icons.star_rounded,
      reduceMotion: reduceMotion,
    );
  }
}
