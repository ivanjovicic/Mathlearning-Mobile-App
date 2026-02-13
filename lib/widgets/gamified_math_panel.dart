import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Helper widget for rendering mathematical expressions with optimal quality.
/// 
/// Supports:
/// - Pure LaTeX expressions (e.g., `\frac{a}{b}`, `\int x dx`)
/// - Inline mixed text with LaTeX (e.g., "Calculate $x^2 + 3x$ when...")
/// - Plain text fallback
/// - Multi-line LaTeX blocks
class GamifiedMathPanel extends StatelessWidget {
  final String formula;
  final String title;
  final String subtitle;
  final IconData icon;
  final TextStyle? expressionTextStyle;

  const GamifiedMathPanel({
    super.key,
    required this.formula,
    required this.title,
    required this.subtitle,
    this.icon = Icons.calculate_rounded,
    this.expressionTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expression = _normalizeMathDelimiters(formula.trim());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.88),
            colorScheme.secondaryContainer.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.onPrimaryContainer, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: _buildExpressionContent(context, expression),
          ),
        ],
      ),
    );
  }

  Widget _buildExpressionContent(BuildContext context, String expression) {
    if (_hasInlineMathSegments(expression)) {
      final parts = _splitInlineMath(expression);
      final hasMultiline = parts.any(
        (part) => part.kind == _InlinePartKind.math && _isMultilineTex(part.raw),
      );
      if (hasMultiline) {
        return _buildMixedBlock(context, parts);
      }
      // Avoid RichText+WidgetSpan baseline quirks (especially on web) by using
      // a normal Wrap with Math widgets.
      return _buildInlineMixedWrap(context, parts);
    }

    if (_looksLikeMathExpression(expression)) {
      if (_isMultilineTex(expression)) {
        return _buildMultilineMath(context, expression);
      }

      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return Math.tex(
        _normalizeTex(expression, allowLineBreaks: false),
        mathStyle: MathStyle.display,
        textStyle:
            expressionTextStyle ??
            theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
        onErrorFallback: (_) => _buildPlainText(context, expression),
      );
    }

    return _buildPlainText(context, expression);
  }

  Widget _buildPlainText(BuildContext context, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      value,
      softWrap: true,
      textWidthBasis: TextWidthBasis.longestLine,
      style:
          expressionTextStyle ??
          theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0.5,
          ),
    );
  }

  Widget _buildMixedBlock(BuildContext context, List<_InlinePart> parts) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style =
        expressionTextStyle ??
        theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          height: 1.4,
        );

    final children = <Widget>[];

    for (final part in parts) {
      final raw = part.raw;
      if (raw.trim().isEmpty) continue;

      if (part.kind == _InlinePartKind.text) {
        // Skip punctuation-only fragments like "," that come from "..., $tex$,".
        final trimmed = raw.trim();
        if (RegExp(r'^[,.;:]+$').hasMatch(trimmed)) continue;
        children.add(
          Text(
            raw,
            style: style,
            softWrap: true,
            textWidthBasis: TextWidthBasis.longestLine,
          ),
        );
        continue;
      }

      if (_isMultilineTex(raw)) {
        children.add(_buildMultilineMath(context, raw));
      } else {
        children.add(
          Math.tex(
            _normalizeTex(raw, allowLineBreaks: false),
            mathStyle: MathStyle.display,
            textStyle: style,
            onErrorFallback: (_) => Text(
              raw,
              style: style,
              softWrap: true,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
          ),
        );
      }
    }

    if (children.isEmpty) {
      return _buildPlainText(context, parts.map((p) => p.raw).join());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildInlineMixedWrap(BuildContext context, List<_InlinePart> parts) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle =
        expressionTextStyle ??
        theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          height: 1.4, // Better line height for mixed text
        ) ??
        TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
        );
    final children = <Widget>[];

    for (final part in parts) {
      final raw = part.raw;
      if (raw.trim().isEmpty) continue;

      if (part.kind == _InlinePartKind.text) {
        children.add(
          Text(
            raw,
            style: textStyle,
            softWrap: true,
            textWidthBasis: TextWidthBasis.longestLine,
          ),
        );
        continue;
      }

      final normalized = _normalizeTex(raw, allowLineBreaks: false);
      children.add(
        Math.tex(
          normalized,
          mathStyle: MathStyle.text,
          textStyle: textStyle.copyWith(
            fontSize: (textStyle.fontSize ?? 18) * 1.05,
          ),
          onErrorFallback: (_) => Text(
            '\$$raw\$',
            style: textStyle,
            softWrap: true,
            textWidthBasis: TextWidthBasis.longestLine,
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return _buildPlainText(context, parts.map((p) => p.raw).join());
    }

    return Wrap(
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      spacing: 6,
      children: children,
    );
  }

  bool _hasInlineMathSegments(String value) {
    return RegExp(r'\$[^$]+\$').hasMatch(value);
  }

  List<_InlinePart> _splitInlineMath(String value) {
    final pattern = RegExp(r'\$([^$]+)\$');
    final parts = <_InlinePart>[];
    var current = 0;

    for (final match in pattern.allMatches(value)) {
      if (match.start > current) {
        parts.add(
          _InlinePart(_InlinePartKind.text, value.substring(current, match.start)),
        );
      }

      final tex = match.group(1);
      parts.add(
        _InlinePart(_InlinePartKind.math, tex ?? ''),
      );
      current = match.end;
    }

    if (current < value.length) {
      parts.add(_InlinePart(_InlinePartKind.text, value.substring(current)));
    }

    return parts;
  }

  bool _isMultilineTex(String tex) {
    final value = tex.trim();
    if (value.isEmpty) return false;

    // TeX environments or explicit line breaks indicate a multiline block.
    if (value.contains(r'\begin{') && value.contains(r'\end{')) return true;
    return value.contains(r'\\');
  }

  Widget _buildMultilineMath(BuildContext context, String tex) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style =
        expressionTextStyle ??
        theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          height: 1.3,
        );

    final normalized = _normalizeTex(tex, allowLineBreaks: true);
    final cleaned = normalized
        .replaceAll(RegExp(r'\\begin\{[^}]+\}'), '')
        .replaceAll(RegExp(r'\\end\{[^}]+\}'), '')
        // Alignment markers are common in aligned/cases envs.
        .replaceAll('&', '');

    final lines =
        cleaned
            .split(RegExp(r'\\\\(\[[^\]]+\])?'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();

    if (lines.isEmpty) {
      return Text(
        tex,
        style: style,
        softWrap: true,
        textWidthBasis: TextWidthBasis.longestLine,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < lines.length; i++) ...[
          Math.tex(
            _normalizeTex(lines[i], allowLineBreaks: false),
            mathStyle: MathStyle.display,
            textStyle: style,
            onErrorFallback: (_) => Text(
              lines[i],
              style: style,
              softWrap: true,
              textWidthBasis: TextWidthBasis.longestLine,
            ),
          ),
          if (i != lines.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  String _normalizeTex(String tex, {required bool allowLineBreaks}) {
    final value = tex.trim();

    // If the backend double-escaped backslashes, TeX commands arrive like
    // "\\sqrt" (which then fails to render). For single-line math, we can safely
    // collapse backslash runs. For multiline blocks, only do this when we see
    // doubled line breaks ("\\\\").
    if (allowLineBreaks) {
      if (!value.contains(r'\\\\')) return value;
      return _halveBackslashRuns(value);
    }

    return _halveBackslashRuns(value);
  }

  String _halveBackslashRuns(String input) {
    if (!input.contains(r'\\')) return input;

    final sb = StringBuffer();
    var i = 0;

    while (i < input.length) {
      final code = input.codeUnitAt(i);
      if (code != 92) {
        sb.writeCharCode(code);
        i++;
        continue;
      }

      var j = i;
      while (j < input.length && input.codeUnitAt(j) == 92) {
        j++;
      }

      final runLength = j - i;
      final reduced = (runLength + 1) ~/ 2; // ceil(runLength / 2)
      for (var k = 0; k < reduced; k++) {
        sb.write('\\');
      }

      i = j;
    }

    return sb.toString();
  }

  String _normalizeMathDelimiters(String value) {
    // Unescape \$ ... \$ that sometimes arrives from JSON/DB.
    var out = value.replaceAll(r'\$', r'$');

    // Convert common TeX delimiters to $...$ so a single parser path handles them.
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

  bool _looksLikeMathExpression(String value) {
    if (value.isEmpty) return false;

    // Strong TeX indicators.
    if (value.contains(r'$$') ||
        value.contains(r'\(') ||
        value.contains(r'\[') ||
        value.contains('{') ||
        value.contains('}') ||
        RegExp(r'\\[a-zA-Z]+').hasMatch(value)) {
      return true;
    }

    // Operator-heavy short expressions (e.g. "2 + 2 = ?", "x^2 + 3x = 0").
    final hasMathOps = RegExp(r'[+\-*/=^_]').hasMatch(value);
    final hasLongWord = RegExp(r'[A-Za-z]{4,}').hasMatch(value);
    return hasMathOps && !hasLongWord;
  }
}

enum _InlinePartKind { text, math }

class _InlinePart {
  final _InlinePartKind kind;
  final String raw;

  _InlinePart(this.kind, this.raw);
}
