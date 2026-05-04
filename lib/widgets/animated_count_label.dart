import 'package:flutter/material.dart';

/// Counts up from [from] to [to] over [duration].
///
/// Uses [TweenAnimationBuilder] so it is automatically re-triggered whenever
/// the [to] value changes. Pair with [prefix] / [suffix] for "+120 XP" style
/// labels.
class AnimatedCountLabel extends StatelessWidget {
  const AnimatedCountLabel({
    super.key,
    required this.to,
    this.from = 0,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
    this.style,
  });

  final int from;
  final int to;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: from.toDouble(), end: to.toDouble()),
      duration: duration,
      curve: curve,
      builder: (context, value, _) {
        return Text(
          '$prefix${value.round()}$suffix',
          style: style,
        );
      },
    );
  }
}
