import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'dart:math' as math;

import 'math_content_parser.dart';
import 'math_content_segment.dart';
import 'math_semantics.dart';
import 'math_view_mode.dart';

class MathRenderer extends StatelessWidget {
  const MathRenderer({
    super.key,
    required this.value,
    this.mode = MathViewMode.compactInline,
    this.style,
    this.textAlign = TextAlign.start,
    this.semanticLabel,
    this.center = false,
    this.forceDisplay = false,
  });

  final String value;
  final MathViewMode mode;
  final TextStyle? style;
  final TextAlign textAlign;
  final String? semanticLabel;
  final bool center;
  final bool forceDisplay;

  @override
  Widget build(BuildContext context) {
    final parseResult = MathContentParser.parse(value);
    final spec = _MathRenderSpec.resolve(
      context,
      mode: mode,
      styleOverride: style,
      textAlign: center ? TextAlign.center : textAlign,
    );

    final label =
        semanticLabel ?? MathSemantics.describeSegments(parseResult.segments);

    final child = _buildContent(context, parseResult, spec);
    return Semantics(
      container: true,
      label: label,
      readOnly: true,
      child: ExcludeSemantics(
        child: Align(
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MathContentParseResult parseResult,
    _MathRenderSpec spec,
  ) {
    if (parseResult.segments.isEmpty) {
      return Text('', textAlign: spec.textAlign, style: spec.textStyle);
    }

    if (parseResult.segments.every(
      (segment) => segment.type == MathContentSegmentType.text,
    )) {
      return Text(
        parseResult.segments.first.value,
        textAlign: spec.textAlign,
        style: spec.textStyle,
        softWrap: true,
        textWidthBasis: TextWidthBasis.parent,
      );
    }

    if (_canRenderInline(parseResult.segments, spec)) {
      return _buildInlineGroup(parseResult.segments, spec);
    }

    final blocks = <Widget>[];
    final inlineBuffer = <MathContentSegment>[];

    void flushInlineBuffer() {
      if (inlineBuffer.isEmpty) {
        return;
      }
      blocks.add(
        _buildInlineGroup(List<MathContentSegment>.from(inlineBuffer), spec),
      );
      inlineBuffer.clear();
    }

    for (final segment in parseResult.segments) {
      if (_shouldRenderAsDisplay(segment, spec)) {
        flushInlineBuffer();
        blocks.add(_buildDisplayMath(segment.value, spec));
      } else {
        inlineBuffer.add(segment);
      }
    }

    flushInlineBuffer();

    if (blocks.length == 1) {
      return blocks.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < blocks.length; index++) ...[
          blocks[index],
          if (index != blocks.length - 1) SizedBox(height: spec.blockSpacing),
        ],
      ],
    );
  }

  bool _canRenderInline(
    List<MathContentSegment> segments,
    _MathRenderSpec spec,
  ) {
    for (final segment in segments) {
      if (_shouldRenderAsDisplay(segment, spec)) {
        return false;
      }
    }
    return true;
  }

  bool _shouldRenderAsDisplay(
    MathContentSegment segment,
    _MathRenderSpec spec,
  ) {
    if (forceDisplay && segment.isMath) {
      return true;
    }

    if (segment.type == MathContentSegmentType.displayMath) {
      return true;
    }

    if (segment.type != MathContentSegmentType.inlineMath) {
      return false;
    }

    final tex = segment.value;
    final operatorCount = RegExp(
      r'[+\-*/=^_|<>\u00b1\u00d7\u00f7]',
    ).allMatches(tex).length;
    final commandCount = RegExp(r'\\[A-Za-z]+').allMatches(tex).length;
    final hasMultiline = tex.contains('\n') || tex.contains(r'\\');
    final hasEnvironment = tex.contains(r'\begin{');
    final adjustedInlineMathCharacterLimit = spec.screenWidth <= 360
        ? spec.inlineMathCharacterLimit - 4
        : spec.inlineMathCharacterLimit;
    final adjustedOperatorLimit = math.max(
      2,
      spec.maxInlineOperatorCount -
          (spec.screenWidth <= 360 ? 1 : 0) -
          (spec.textScaleFactor >= 1.3 ? 1 : 0),
    );

    return hasMultiline ||
        hasEnvironment ||
        tex.length > adjustedInlineMathCharacterLimit ||
        operatorCount >= adjustedOperatorLimit ||
        (commandCount >= 3 &&
            tex.length > adjustedInlineMathCharacterLimit ~/ 2);
  }

  Widget _buildInlineGroup(
    List<MathContentSegment> segments,
    _MathRenderSpec spec,
  ) {
    final children = <Widget>[];
    for (final segment in segments) {
      if (segment.type == MathContentSegmentType.text) {
        children.add(
          Text(
            segment.value,
            style: spec.textStyle,
            softWrap: true,
            textWidthBasis: TextWidthBasis.parent,
          ),
        );
      } else {
        children.add(_buildInlineMath(segment.value, spec));
      }
    }

    return Wrap(
      alignment: _wrapAlignmentFor(spec.textAlign),
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: spec.inlineRunSpacing,
      spacing: spec.inlineSpacing,
      children: children,
    );
  }

  Widget _buildInlineMath(String tex, _MathRenderSpec spec) {
    return Math.tex(
      MathContentParser.normalizeTex(tex),
      mathStyle: MathStyle.text,
      textStyle: spec.inlineMathTextStyle,
      onErrorFallback: (error) {
        _logFailure(tex, error, spec.mode);
        return Text(
          MathSemantics.texToReadableText(tex),
          style: spec.textStyle,
          softWrap: true,
        );
      },
    );
  }

  Widget _buildDisplayMath(String tex, _MathRenderSpec spec) {
    final math = Math.tex(
      MathContentParser.normalizeTex(tex, allowLineBreaks: true),
      mathStyle: MathStyle.display,
      textStyle: spec.displayMathTextStyle,
      onErrorFallback: (error) {
        _logFailure(tex, error, spec.mode);
        return Text(
          MathSemantics.texToReadableText(tex),
          textAlign: spec.textAlign,
          style: spec.textStyle,
          softWrap: true,
          textWidthBasis: TextWidthBasis.parent,
        );
      },
    );

    return Container(
      width: double.infinity,
      padding: spec.displayPadding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: math,
        ),
      ),
    );
  }

  WrapAlignment _wrapAlignmentFor(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.center:
        return WrapAlignment.center;
      case TextAlign.end:
      case TextAlign.right:
        return WrapAlignment.end;
      case TextAlign.justify:
      case TextAlign.left:
      case TextAlign.start:
        return WrapAlignment.start;
    }
  }

  void _logFailure(String tex, FlutterMathException error, MathViewMode mode) {
    debugPrint('[MathRenderer] Failed to render TeX in $mode: $tex ($error)');
  }
}

class _MathRenderSpec {
  const _MathRenderSpec({
    required this.mode,
    required this.textStyle,
    required this.inlineMathTextStyle,
    required this.displayMathTextStyle,
    required this.textAlign,
    required this.blockSpacing,
    required this.displayPadding,
    required this.inlineMathCharacterLimit,
    required this.maxInlineOperatorCount,
    required this.inlineSpacing,
    required this.inlineRunSpacing,
    required this.screenWidth,
    required this.textScaleFactor,
  });

  final MathViewMode mode;
  final TextStyle textStyle;
  final TextStyle inlineMathTextStyle;
  final TextStyle displayMathTextStyle;
  final TextAlign textAlign;
  final double blockSpacing;
  final EdgeInsets displayPadding;
  final int inlineMathCharacterLimit;
  final int maxInlineOperatorCount;
  final double inlineSpacing;
  final double inlineRunSpacing;
  final double screenWidth;
  final double textScaleFactor;

  factory _MathRenderSpec.resolve(
    BuildContext context, {
    required MathViewMode mode,
    required TextStyle? styleOverride,
    required TextAlign textAlign,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final color =
        styleOverride?.color ?? Theme.of(context).colorScheme.onSurface;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1);

    TextStyle baseStyle;
    double blockSpacing;
    EdgeInsets displayPadding;
    int inlineMathCharacterLimit;
    int maxInlineOperatorCount;
    double inlineSpacing;

    switch (mode) {
      case MathViewMode.questionStem:
        baseStyle =
            styleOverride ??
            textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: color,
            ) ??
            TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: color,
            );
        blockSpacing = 12;
        displayPadding = const EdgeInsets.symmetric(vertical: 4);
        inlineMathCharacterLimit = 24;
        maxInlineOperatorCount = 5;
        inlineSpacing = 2;
      case MathViewMode.answerOption:
        baseStyle =
            styleOverride ??
            textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: color,
            ) ??
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: color,
            );
        blockSpacing = 8;
        displayPadding = const EdgeInsets.symmetric(vertical: 2);
        inlineMathCharacterLimit = 22;
        maxInlineOperatorCount = 5;
        inlineSpacing = 2;
      case MathViewMode.hint:
        baseStyle =
            styleOverride ??
            textTheme.bodyMedium?.copyWith(height: 1.4, color: color) ??
            TextStyle(fontSize: 14, height: 1.4, color: color);
        blockSpacing = 10;
        displayPadding = const EdgeInsets.symmetric(vertical: 2);
        inlineMathCharacterLimit = 22;
        maxInlineOperatorCount = 5;
        inlineSpacing = 2;
      case MathViewMode.explanationStep:
        baseStyle =
            styleOverride ??
            textTheme.bodyLarge?.copyWith(height: 1.45, color: color) ??
            TextStyle(fontSize: 16, height: 1.45, color: color);
        blockSpacing = 10;
        displayPadding = const EdgeInsets.symmetric(vertical: 4);
        inlineMathCharacterLimit = 24;
        maxInlineOperatorCount = 5;
        inlineSpacing = 2;
      case MathViewMode.review:
        baseStyle =
            styleOverride ??
            textTheme.bodyMedium?.copyWith(height: 1.35, color: color) ??
            TextStyle(fontSize: 14, height: 1.35, color: color);
        blockSpacing = 8;
        displayPadding = const EdgeInsets.symmetric(vertical: 2);
        inlineMathCharacterLimit = 20;
        maxInlineOperatorCount = 4;
        inlineSpacing = 2;
      case MathViewMode.compactInline:
        baseStyle =
            styleOverride ??
            textTheme.bodyMedium?.copyWith(height: 1.35, color: color) ??
            TextStyle(fontSize: 14, height: 1.35, color: color);
        blockSpacing = 6;
        displayPadding = const EdgeInsets.symmetric(vertical: 2);
        inlineMathCharacterLimit = 18;
        maxInlineOperatorCount = 4;
        inlineSpacing = 1;
    }

    return _MathRenderSpec(
      mode: mode,
      textStyle: baseStyle,
      inlineMathTextStyle: baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14) * 1.02,
      ),
      displayMathTextStyle: baseStyle.copyWith(
        fontSize:
            (baseStyle.fontSize ?? 14) *
            (mode == MathViewMode.answerOption ? 1.0 : 1.08),
      ),
      textAlign: textAlign,
      blockSpacing: blockSpacing,
      displayPadding: displayPadding,
      inlineMathCharacterLimit: inlineMathCharacterLimit,
      maxInlineOperatorCount: maxInlineOperatorCount,
      inlineSpacing: inlineSpacing,
      inlineRunSpacing: mode == MathViewMode.answerOption ? 2 : 4,
      screenWidth: screenWidth,
      textScaleFactor: textScaleFactor,
    );
  }
}
