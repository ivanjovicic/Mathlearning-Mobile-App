import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathContentText extends StatelessWidget {
  const MathContentText({
    super.key,
    required this.value,
    this.style,
    this.textAlign = TextAlign.start,
    this.semanticLabel,
  });

  final String value;
  final TextStyle? style;
  final TextAlign textAlign;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeMathDelimiters(value.trim());
    final effectiveStyle = style ?? Theme.of(context).textTheme.bodyMedium;

    Widget child;
    if (_hasInlineMathSegments(normalized)) {
      child = RichText(
        textAlign: textAlign,
        text: TextSpan(
          style: effectiveStyle,
          children: _buildInlineSpans(normalized, effectiveStyle),
        ),
        textWidthBasis: TextWidthBasis.parent,
        softWrap: true,
      );
    } else if (_looksLikeMathExpression(normalized)) {
      child = Math.tex(
        _normalizeTex(normalized),
        mathStyle: MathStyle.display,
        textStyle: effectiveStyle,
        onErrorFallback: (_) => Text(
          normalized,
          textAlign: textAlign,
          style: effectiveStyle,
          softWrap: true,
          textWidthBasis: TextWidthBasis.parent,
        ),
      );
    } else {
      child = Text(
        normalized,
        textAlign: textAlign,
        style: effectiveStyle,
        softWrap: true,
        textWidthBasis: TextWidthBasis.parent,
      );
    }

    return Semantics(
      label: semanticLabel ?? normalized,
      readOnly: true,
      child: child,
    );
  }

  List<InlineSpan> _buildInlineSpans(String normalized, TextStyle? style) {
    final pattern = RegExp(r'\$([^$]+)\$');
    final spans = <InlineSpan>[];
    var current = 0;

    for (final match in pattern.allMatches(normalized)) {
      if (match.start > current) {
        spans.add(
          TextSpan(
            text: normalized.substring(current, match.start),
            style: style,
          ),
        );
      }

      final tex = match.group(1);
      if (tex != null && tex.isNotEmpty) {
        spans.add(
          TextSpan(
            text: _inlineMathToReadableText(tex),
            style: style,
          ),
        );
      }

      current = match.end;
    }

    if (current < normalized.length) {
      spans.add(TextSpan(text: normalized.substring(current), style: style));
    }

    return spans;
  }

  String _normalizeMathDelimiters(String value) {
    var out = value.replaceAll(r'\$', r'$');
    out = out.replaceAllMapped(
      RegExp(r'\\\((.*?)\\\)', dotAll: true),
      (m) => '\$${m.group(1) ?? ''}\$',
    );
    out = out.replaceAllMapped(
      RegExp(r'\\\[(.*?)\\\]', dotAll: true),
      (m) => '\$${m.group(1) ?? ''}\$',
    );
    out = out.replaceAllMapped(
      RegExp(r'\$\$(.*?)\$\$', dotAll: true),
      (m) => '\$${m.group(1) ?? ''}\$',
    );
    return out;
  }

  bool _hasInlineMathSegments(String value) {
    return RegExp(r'\$[^$]+\$').hasMatch(value);
  }

  bool _looksLikeMathExpression(String value) {
    if (value.isEmpty) return false;
    if (value.contains(r'\') ||
        value.contains('=') ||
        value.contains('^') ||
        value.contains('{') ||
        value.contains('}')) {
      return true;
    }
    final hasMathOps = RegExp(r'[+\-*/=_]').hasMatch(value);
    final hasLongWord = RegExp(r'[A-Za-z]{4,}').hasMatch(value);
    return hasMathOps && !hasLongWord;
  }

  String _normalizeTex(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'^\$(.*)\$$', dotAll: true),
          (match) => match.group(1) ?? value,
        )
        .replaceAll(r'\\\(', '')
        .replaceAll(r'\\\)', '')
        .replaceAll(r'\\\[', '')
        .replaceAll(r'\\\]', '')
        .trim();
  }

  String _inlineMathToReadableText(String tex) {
    var value = _normalizeTex(tex);

    value = value.replaceAllMapped(
      RegExp(r'\\frac\s*\{([^{}]+)\}\s*\{([^{}]+)\}'),
      (m) => '(${m.group(1)})/(${m.group(2)})',
    );
    value = value.replaceAllMapped(
      RegExp(r'\\sqrt\s*\{([^{}]+)\}'),
      (m) => 'sqrt(${m.group(1)})',
    );

    const replacements = <String, String>{
      r'\cdot': '*',
      r'\times': 'x',
      r'\div': '/',
      r'\pm': '+/-',
      r'\ge': '>=',
      r'\le': '<=',
      r'\neq': '!=',
      r'\left': '',
      r'\right': '',
    };
    replacements.forEach((from, to) {
      value = value.replaceAll(from, to);
    });

    value = value.replaceAll('{', '');
    value = value.replaceAll('}', '');
    value = value.replaceAll(r'\', '');
    value = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return value;
  }
}
