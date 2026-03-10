import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/math/math_content_parser.dart';
import 'package:mathlearning/widgets/math/math_content_segment.dart';

void main() {
  test('splits mixed text and inline math segments', () {
    final result = MathContentParser.parse(r'Compute $x^2$ when x = 4');

    expect(result.segments.length, 3);
    expect(result.segments[0].type, MathContentSegmentType.text);
    expect(result.segments[0].value, 'Compute ');
    expect(result.segments[1].type, MathContentSegmentType.inlineMath);
    expect(result.segments[1].value, 'x^2');
    expect(result.segments[2].type, MathContentSegmentType.text);
    expect(result.segments[2].value, ' when x = 4');
  });

  test('parses display math from legacy delimiters', () {
    final result = MathContentParser.parse(r'\[\frac{1}{2}+\frac{1}{3}\]');

    expect(result.segments.length, 1);
    expect(result.segments.single.type, MathContentSegmentType.displayMath);
    expect(result.segments.single.value, r'\frac{1}{2}+\frac{1}{3}');
  });

  test('treats malformed latex delimiter as safe text', () {
    final result = MathContentParser.parse(r'Compute $x^2 when x = 4');

    expect(result.segments.length, 1);
    expect(result.segments.single.type, MathContentSegmentType.text);
    expect(result.segments.single.value, r'Compute $x^2 when x = 4');
  });

  test('detects implicit multiline formulas as display math', () {
    final result = MathContentParser.parse(
      r'x = \frac{-b\pm\sqrt{b^2-4ac}}{2a}\\x = 3',
    );

    expect(result.segments.length, 1);
    expect(result.segments.single.type, MathContentSegmentType.displayMath);
  });
}
