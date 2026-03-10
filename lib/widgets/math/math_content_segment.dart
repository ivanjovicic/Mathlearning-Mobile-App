enum MathContentSegmentType {
  text,
  inlineMath,
  displayMath,
}

class MathContentSegment {
  const MathContentSegment._({
    required this.type,
    required this.value,
  });

  const MathContentSegment.text(String value)
    : this._(type: MathContentSegmentType.text, value: value);

  const MathContentSegment.inlineMath(String value)
    : this._(type: MathContentSegmentType.inlineMath, value: value);

  const MathContentSegment.displayMath(String value)
    : this._(type: MathContentSegmentType.displayMath, value: value);

  final MathContentSegmentType type;
  final String value;

  bool get isMath => type != MathContentSegmentType.text;

  bool get isDisplayMath => type == MathContentSegmentType.displayMath;
}
