import 'math_content_parser.dart';
import 'math_content_segment.dart';

class MathSemantics {
  const MathSemantics._();

  static String labelForRawContent(String raw) {
    return describeSegments(MathContentParser.parse(raw).segments);
  }

  static String describeSegments(List<MathContentSegment> segments) {
    if (segments.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (final segment in segments) {
      if (segment.type == MathContentSegmentType.text) {
        buffer.write(segment.value);
      } else {
        buffer.write(_texToReadableText(segment.value));
      }
    }
    return _collapseSpacing(buffer.toString());
  }

  static String texToReadableText(String tex) {
    return _collapseSpacing(_texToReadableText(MathContentParser.normalizeTex(tex)));
  }

  static String _texToReadableText(String tex) {
    var value = MathContentParser.normalizeTex(tex, allowLineBreaks: true);

    final fractionPattern = RegExp(r'\\frac\s*\{([^{}]+)\}\s*\{([^{}]+)\}');
    while (fractionPattern.hasMatch(value)) {
      value = value.replaceAllMapped(
        fractionPattern,
        (match) =>
            '${match.group(1)} over ${match.group(2)}',
      );
    }

    final sqrtPattern = RegExp(r'\\sqrt\s*(?:\[(.*?)\])?\s*\{([^{}]+)\}');
    while (sqrtPattern.hasMatch(value)) {
      value = value.replaceAllMapped(sqrtPattern, (match) {
        final index = match.group(1);
        final body = match.group(2);
        if (index == null || index.trim().isEmpty) {
          return 'square root of $body';
        }
        return '$index root of $body';
      });
    }

    value = value.replaceAllMapped(
      RegExp(r'([A-Za-z0-9)\]])\^\{([^{}]+)\}'),
      (match) => '${match.group(1)} to the power of ${match.group(2)}',
    );
    value = value.replaceAllMapped(
      RegExp(r'([A-Za-z0-9)\]])\^([A-Za-z0-9+\-]+)'),
      (match) => '${match.group(1)} to the power of ${match.group(2)}',
    );
    value = value.replaceAllMapped(
      RegExp(r'([A-Za-z0-9)\]])_\{([^{}]+)\}'),
      (match) => '${match.group(1)} sub ${match.group(2)}',
    );
    value = value.replaceAllMapped(
      RegExp(r'([A-Za-z0-9)\]])_([A-Za-z0-9+\-]+)'),
      (match) => '${match.group(1)} sub ${match.group(2)}',
    );

    const commandReplacements = <String, String>{
      r'\cdot': ' times ',
      r'\times': ' times ',
      r'\div': ' divided by ',
      r'\pm': ' plus or minus ',
      r'\mp': ' minus or plus ',
      r'\ge': ' greater than or equal to ',
      r'\le': ' less than or equal to ',
      r'\neq': ' not equal to ',
      r'\approx': ' approximately ',
      r'\sin': ' sine ',
      r'\cos': ' cosine ',
      r'\tan': ' tangent ',
      r'\log': ' log ',
      r'\ln': ' natural log ',
      r'\int': ' integral ',
      r'\sum': ' sum ',
      r'\prod': ' product ',
      r'\pi': ' pi ',
      r'\theta': ' theta ',
      r'\alpha': ' alpha ',
      r'\beta': ' beta ',
      r'\gamma': ' gamma ',
      r'\Delta': ' delta ',
      r'\infty': ' infinity ',
      r'\left': ' ',
      r'\right': ' ',
      r'\to': ' to ',
      r'\Rightarrow': ' implies ',
      r'\iff': ' if and only if ',
      r'\,': ' ',
      r'\;': ' ',
      r'\:': ' ',
      r'\!': ' ',
    };

    commandReplacements.forEach((from, to) {
      value = value.replaceAll(from, to);
    });

    value = value
        .replaceAll(r'\\', ', ')
        .replaceAll('{', ' ')
        .replaceAll('}', ' ')
        .replaceAll('&', ' ')
        .replaceAll(r'\', ' ');

    return value;
  }

  static String _collapseSpacing(String value) {
    return value
        .replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
