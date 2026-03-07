import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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
    final normalized = expression.trim();
    final effectiveStyle =
        textStyle ??
        Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    final child = _looksLikeMath(normalized)
        ? Math.tex(
            _normalizeTex(normalized),
            mathStyle: MathStyle.display,
            textStyle: effectiveStyle,
            onErrorFallback: (_) => Text(
              normalized,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: effectiveStyle,
            ),
          )
        : Text(
            normalized,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: effectiveStyle,
          );

    return Semantics(
      label: semanticLabel ?? 'Math expression: $normalized',
      readOnly: true,
      child: Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: child,
      ),
    );
  }

  bool _looksLikeMath(String value) {
    if (value.isEmpty) return false;
    if (value.contains(r'\') ||
        value.contains('=') ||
        value.contains('^') ||
        value.contains('√')) {
      return true;
    }
    final hasOperators = RegExp(r'[+\-*/]').hasMatch(value);
    final hasDigits = RegExp(r'\d').hasMatch(value);
    return hasOperators && hasDigits;
  }

  String _normalizeTex(String value) {
    var output = value;
    output = output.replaceAllMapped(
      RegExp(r'^\$(.*)\$$', dotAll: true),
      (match) => match.group(1) ?? value,
    );
    output = output.replaceAll(r'\\\(', '').replaceAll(r'\\\)', '');
    output = output.replaceAll(r'\\\[', '').replaceAll(r'\\\]', '');
    return output.trim();
  }
}
