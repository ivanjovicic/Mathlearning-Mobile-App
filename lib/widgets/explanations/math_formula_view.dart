import 'package:flutter/material.dart';

import '../math/math_renderer.dart';
import '../math/math_view_mode.dart';

class MathFormulaView extends StatelessWidget {
  const MathFormulaView({
    super.key,
    required this.expression,
    this.semanticLabel,
    this.textStyle,
    this.center = true,
  });

  final String expression;
  final String? semanticLabel;
  final TextStyle? textStyle;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return MathRenderer(
      value: expression,
      mode: MathViewMode.explanationStep,
      style: textStyle,
      textAlign: center ? TextAlign.center : TextAlign.start,
      semanticLabel: semanticLabel,
      center: center,
      forceDisplay: true,
    );
  }
}
