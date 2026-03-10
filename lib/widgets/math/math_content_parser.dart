import 'math_content_segment.dart';

class MathContentParseResult {
  const MathContentParseResult({
    required this.source,
    required this.normalizedSource,
    required this.segments,
  });

  final String source;
  final String normalizedSource;
  final List<MathContentSegment> segments;

  bool get hasMath => segments.any((segment) => segment.isMath);

  bool get hasDisplayMath =>
      segments.any((segment) => segment.isDisplayMath);
}

class MathContentParser {
  const MathContentParser._();

  static final RegExp _delimitedMathPattern = RegExp(
    r'\$\$(.*?)\$\$|\\\[(.*?)\\\]|\$([^$]+?)\$|\\\((.*?)\\\)',
    dotAll: true,
  );

  static MathContentParseResult parse(String raw) {
    final normalized = normalizeInput(raw);
    if (normalized.isEmpty) {
      return const MathContentParseResult(
        source: '',
        normalizedSource: '',
        segments: <MathContentSegment>[],
      );
    }

    final segments = <MathContentSegment>[];
    var cursor = 0;

    for (final match in _delimitedMathPattern.allMatches(normalized)) {
      if (match.start > cursor) {
        _appendTextSegment(
          segments,
          normalized.substring(cursor, match.start),
        );
      }

      final fullMatch = match.group(0) ?? '';
      if (match.group(1) != null) {
        _appendMathSegment(
          segments,
          MathContentSegmentType.displayMath,
          match.group(1)!,
          fallback: fullMatch,
        );
      } else if (match.group(2) != null) {
        _appendMathSegment(
          segments,
          MathContentSegmentType.displayMath,
          match.group(2)!,
          fallback: fullMatch,
        );
      } else if (match.group(3) != null) {
        _appendMathSegment(
          segments,
          MathContentSegmentType.inlineMath,
          match.group(3)!,
          fallback: fullMatch,
        );
      } else if (match.group(4) != null) {
        _appendMathSegment(
          segments,
          MathContentSegmentType.inlineMath,
          match.group(4)!,
          fallback: fullMatch,
        );
      } else {
        _appendTextSegment(segments, fullMatch);
      }

      cursor = match.end;
    }

    if (cursor < normalized.length) {
      _appendTextSegment(segments, normalized.substring(cursor));
    }

    final compacted = _compactSegments(segments);
    if (compacted.any((segment) => segment.isMath)) {
      return MathContentParseResult(
        source: raw,
        normalizedSource: normalized,
        segments: compacted,
      );
    }

    if (_hasUnbalancedDelimiters(normalized)) {
      return MathContentParseResult(
        source: raw,
        normalizedSource: normalized,
        segments: <MathContentSegment>[MathContentSegment.text(normalized)],
      );
    }

    return MathContentParseResult(
      source: raw,
      normalizedSource: normalized,
      segments: _parseImplicitContent(normalized),
    );
  }

  static String normalizeInput(String raw) {
    if (raw.isEmpty) {
      return '';
    }

    var value = raw.replaceAll('\r\n', '\n').trim();

    const mojibakeFixes = <String, String>{
      'Ãƒâ€”': '\u00d7',
      'ÃƒÂ·': '\u00f7',
      'Ã‚Â·': '\u00b7',
      'Ã‚Â±': '\u00b1',
      'Ã¢Ë†Å¡': '\u221a',
      'Ã¢â€°Â¥': '\u2265',
      'Ã¢â€°Â¤': '\u2264',
      'Ã¢â€° ': '\u2260',
      'Ã¢â‚¬Â¦': '...',
    };

    mojibakeFixes.forEach((from, to) {
      value = value.replaceAll(from, to);
    });

    value = value.replaceAll(r'\$', r'$');
    return value;
  }

  static String normalizeTex(
    String raw, {
    bool allowLineBreaks = false,
  }) {
    var value = raw.trim();
    if (value.isEmpty) {
      return '';
    }

    value = value
        .replaceAllMapped(
          RegExp(r'^\$(.*)\$$', dotAll: true),
          (match) => match.group(1) ?? value,
        )
        .replaceAll(r'\\\(', '')
        .replaceAll(r'\\\)', '')
        .replaceAll(r'\\\[', '')
        .replaceAll(r'\\\]', '')
        .trim();

    if (allowLineBreaks) {
      if (!value.contains(r'\\\\')) {
        return value;
      }
      return _halveBackslashRuns(value);
    }

    return _halveBackslashRuns(value);
  }

  static bool looksLikeMath(String value) {
    final normalized = normalizeInput(value);
    if (normalized.isEmpty) {
      return false;
    }

    if (RegExp(r'\\[A-Za-z]+').hasMatch(normalized)) {
      return true;
    }

    if (normalized.contains('^') ||
        normalized.contains('_') ||
        normalized.contains('{') ||
        normalized.contains('}') ||
        normalized.contains('\u221a')) {
      return true;
    }

    final hasOperators = RegExp(r'[+\-*/=|<>\u00b1\u00d7\u00f7]').hasMatch(
      normalized,
    );
    final hasNumbers = RegExp(r'\d').hasMatch(normalized);
    final hasCompactVariables =
        RegExp(r'[A-Za-z]\d|\d[A-Za-z]|\b[A-Za-z]\b').hasMatch(normalized);
    final longWords = RegExp(r'\b[A-Za-z]{4,}\b')
        .allMatches(normalized)
        .length;

    if ((hasOperators && (hasNumbers || hasCompactVariables)) &&
        longWords == 0) {
      return true;
    }

    return false;
  }

  static bool looksLikeDisplayMath(String value) {
    final normalized = normalizeInput(value);
    if (normalized.isEmpty) {
      return false;
    }

    if (normalized.contains('\n') ||
        normalized.contains(r'\\') ||
        normalized.contains(r'\begin{')) {
      return true;
    }

    final operatorCount = RegExp(r'[+\-*/=^_|<>\u00b1\u00d7\u00f7]')
        .allMatches(normalized)
        .length;
    final commandCount = RegExp(r'\\[A-Za-z]+').allMatches(normalized).length;

    return looksLikeMath(normalized) &&
        (normalized.length >= 24 ||
            operatorCount >= 5 ||
            commandCount >= 3);
  }

  static void _appendTextSegment(
    List<MathContentSegment> segments,
    String text,
  ) {
    if (text.isEmpty) {
      return;
    }

    if (segments.isNotEmpty &&
        segments.last.type == MathContentSegmentType.text) {
      final previous = segments.removeLast();
      segments.add(MathContentSegment.text(previous.value + text));
      return;
    }

    segments.add(MathContentSegment.text(text));
  }

  static void _appendMathSegment(
    List<MathContentSegment> segments,
    MathContentSegmentType type,
    String value, {
    required String fallback,
  }) {
    final normalized = normalizeTex(
      value,
      allowLineBreaks: type == MathContentSegmentType.displayMath,
    );
    if (normalized.isEmpty) {
      _appendTextSegment(segments, fallback);
      return;
    }

    if (type == MathContentSegmentType.displayMath) {
      segments.add(MathContentSegment.displayMath(normalized));
      return;
    }

    if (type == MathContentSegmentType.inlineMath) {
      segments.add(MathContentSegment.inlineMath(normalized));
      return;
    }

    _appendTextSegment(segments, normalized);
  }

  static List<MathContentSegment> _compactSegments(
    List<MathContentSegment> input,
  ) {
    final output = <MathContentSegment>[];
    for (final segment in input) {
      if (segment.value.isEmpty) {
        continue;
      }

      if (output.isNotEmpty &&
          output.last.type == segment.type &&
          segment.type == MathContentSegmentType.text) {
        final previous = output.removeLast();
        output.add(MathContentSegment.text(previous.value + segment.value));
      } else {
        output.add(segment);
      }
    }
    return output;
  }

  static List<MathContentSegment> _parseImplicitContent(String normalized) {
    if (looksLikeDisplayMath(normalized)) {
      return <MathContentSegment>[
        MathContentSegment.displayMath(
          normalizeTex(normalized, allowLineBreaks: true),
        ),
      ];
    }

    if (looksLikeMath(normalized)) {
      return <MathContentSegment>[
        MathContentSegment.inlineMath(normalizeTex(normalized)),
      ];
    }

    return <MathContentSegment>[MathContentSegment.text(normalized)];
  }

  static String _halveBackslashRuns(String input) {
    if (!input.contains(r'\\')) {
      return input;
    }

    final buffer = StringBuffer();
    var index = 0;

    while (index < input.length) {
      if (input.codeUnitAt(index) != 92) {
        buffer.writeCharCode(input.codeUnitAt(index));
        index++;
        continue;
      }

      var runEnd = index;
      while (runEnd < input.length && input.codeUnitAt(runEnd) == 92) {
        runEnd++;
      }

      final runLength = runEnd - index;
      final reduced = (runLength + 1) ~/ 2;
      buffer.write('\\' * reduced);
      index = runEnd;
    }

    return buffer.toString();
  }

  static bool _hasUnbalancedDelimiters(String value) {
    final dollarCount = RegExp(r'(?<!\\)\$').allMatches(value).length;
    if (dollarCount.isOdd) {
      return true;
    }

    final inlineOpenCount = RegExp(r'\\\(').allMatches(value).length;
    final inlineCloseCount = RegExp(r'\\\)').allMatches(value).length;
    if (inlineOpenCount != inlineCloseCount) {
      return true;
    }

    final displayOpenCount = RegExp(r'\\\[').allMatches(value).length;
    final displayCloseCount = RegExp(r'\\\]').allMatches(value).length;
    return displayOpenCount != displayCloseCount;
  }
}
