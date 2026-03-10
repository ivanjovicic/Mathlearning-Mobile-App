import 'package:flutter/material.dart';

import 'math/math_renderer.dart';
import 'math/math_view_mode.dart';

class MathContentText extends StatelessWidget {
  const MathContentText({
    super.key,
    required this.value,
    this.style,
    this.textAlign = TextAlign.start,
    this.semanticLabel,
    this.mode = MathViewMode.compactInline,
    this.center = false,
    this.forceDisplay = false,
  });

  final String value;
  final TextStyle? style;
  final TextAlign textAlign;
  final String? semanticLabel;
  final MathViewMode mode;
  final bool center;
  final bool forceDisplay;

  @override
  Widget build(BuildContext context) {
    return MathRenderer(
      value: value,
      mode: mode,
      style: style,
      textAlign: textAlign,
      semanticLabel: semanticLabel,
      center: center,
      forceDisplay: forceDisplay,
    );
  }
}
