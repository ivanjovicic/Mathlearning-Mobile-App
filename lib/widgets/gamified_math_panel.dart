import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class GamifiedMathPanel extends StatelessWidget {
  final String formula;
  final String title;
  final String subtitle;
  final IconData icon;

  const GamifiedMathPanel({
    super.key,
    required this.formula,
    required this.title,
    required this.subtitle,
    this.icon = Icons.calculate_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final expression = _normalizeInlineMathDelimiters(formula.trim());

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
      return _buildInlineMixedText(context, expression);
    }

    if (_looksLikeMathExpression(expression)) {
      return Math.tex(
        expression,
        mathStyle: MathStyle.display,
        textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w700,
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
      style: theme.textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInlineMixedText(BuildContext context, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );
    final pattern = RegExp(r'\$([^$]+)\$');
    final spans = <InlineSpan>[];
    var current = 0;

    for (final match in pattern.allMatches(value)) {
      if (match.start > current) {
        spans.add(TextSpan(text: value.substring(current, match.start), style: textStyle));
      }

      final tex = match.group(1);
      if (tex == null || tex.isEmpty) {
        spans.add(TextSpan(text: match.group(0), style: textStyle));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(
              tex,
              mathStyle: MathStyle.text,
              textStyle: textStyle,
              onErrorFallback: (_) => Text(
                '\$$tex\$',
                style: textStyle,
              ),
            ),
          ),
        );
      }

      current = match.end;
    }

    if (current < value.length) {
      spans.add(TextSpan(text: value.substring(current), style: textStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
    );
  }

  bool _hasInlineMathSegments(String value) {
    return RegExp(r'\$[^$]+\$').hasMatch(value);
  }

  String _normalizeInlineMathDelimiters(String value) {
    // Backend can return escaped inline delimiters like "\$...\$".
    return value.replaceAll(r'\$', r'$');
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
