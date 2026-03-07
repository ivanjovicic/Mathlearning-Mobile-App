import 'package:flutter/foundation.dart';

import '../../models/step_explanation.dart';

enum MistakeType { signError, denominatorError, orderOfOperations, unknown }

class StepExplanationController extends ChangeNotifier {
  StepExplanationController({
    required List<StepExplanation> steps,
    int initialStepIndex = 0,
    bool mistakeMode = false,
  }) : _steps = List<StepExplanation>.unmodifiable(steps),
       _currentStepIndex = initialStepIndex.clamp(
         0,
         steps.isEmpty ? 0 : steps.length - 1,
       ),
       _mistakeMode = mistakeMode;

  List<StepExplanation> _steps;
  int _currentStepIndex;
  final Set<int> _visibleHintIndices = <int>{};
  bool _mistakeMode;
  MistakeType _mistakeType = MistakeType.unknown;
  int _struggleCount = 0;

  List<StepExplanation> get steps => _steps;
  int get totalSteps => _steps.length;
  bool get hasSteps => _steps.isNotEmpty;
  int get currentStepIndex => _currentStepIndex;
  StepExplanation? get currentStep =>
      hasSteps ? _steps[_currentStepIndex] : null;
  bool get canGoNext => hasSteps && _currentStepIndex < _steps.length - 1;
  bool get canGoPrevious => hasSteps && _currentStepIndex > 0;
  double get progress => hasSteps ? (_currentStepIndex + 1) / _steps.length : 0;

  bool get isMistakeMode => _mistakeMode;
  MistakeType get mistakeType => _mistakeType;
  bool get shouldShowAdaptiveDepth => _struggleCount >= 2;
  int get struggleCount => _struggleCount;

  bool isHintVisible(int stepIndex) => _visibleHintIndices.contains(stepIndex);

  void setSteps(List<StepExplanation> newSteps) {
    _steps = List<StepExplanation>.unmodifiable(newSteps);
    _currentStepIndex = _currentStepIndex.clamp(
      0,
      newSteps.isEmpty ? 0 : newSteps.length - 1,
    );
    _visibleHintIndices.clear();
    notifyListeners();
  }

  void nextStep() {
    if (!canGoNext) return;
    _currentStepIndex++;
    notifyListeners();
  }

  void previousStep() {
    if (!canGoPrevious) return;
    _currentStepIndex--;
    notifyListeners();
  }

  void jumpToStep(int stepIndex) {
    if (!hasSteps) return;
    final nextIndex = stepIndex.clamp(0, _steps.length - 1);
    if (nextIndex == _currentStepIndex) return;
    _currentStepIndex = nextIndex;
    notifyListeners();
  }

  void toggleHint([int? stepIndex]) {
    final index = stepIndex ?? _currentStepIndex;
    if (index < 0 || index >= _steps.length) return;
    if (_visibleHintIndices.contains(index)) {
      _visibleHintIndices.remove(index);
    } else {
      _visibleHintIndices.add(index);
    }
    notifyListeners();
  }

  void setMistakeMode(bool value, {MistakeType type = MistakeType.unknown}) {
    if (_mistakeMode == value && _mistakeType == type) return;
    _mistakeMode = value;
    _mistakeType = type;
    notifyListeners();
  }

  void registerIncorrectAnswer({
    String? studentAnswer,
    String? expectedAnswer,
    String? expression,
  }) {
    _struggleCount++;
    _mistakeMode = true;
    _mistakeType = detectMistakeType(
      studentAnswer: studentAnswer,
      expectedAnswer: expectedAnswer,
      expression: expression,
    );
    notifyListeners();
  }

  void registerCorrectAnswer() {
    _mistakeMode = false;
    _mistakeType = MistakeType.unknown;
    _struggleCount = 0;
    notifyListeners();
  }

  void resetAdaptiveDepth() {
    if (_struggleCount == 0) return;
    _struggleCount = 0;
    notifyListeners();
  }

  static MistakeType detectMistakeType({
    String? studentAnswer,
    String? expectedAnswer,
    String? expression,
  }) {
    final student = _normalize(studentAnswer);
    final expected = _normalize(expectedAnswer);

    if (student.isEmpty || expected.isEmpty) {
      return MistakeType.unknown;
    }

    if (student == '-$expected' || expected == '-$student') {
      return MistakeType.signError;
    }

    if (student.contains('/') && expected.contains('/')) {
      final studentDenominator = _extractDenominator(student);
      final expectedDenominator = _extractDenominator(expected);
      if (studentDenominator.isNotEmpty &&
          expectedDenominator.isNotEmpty &&
          studentDenominator != expectedDenominator) {
        return MistakeType.denominatorError;
      }
    }

    final normalizedExpression = _normalize(expression);
    final hasMixedOperators =
        normalizedExpression.contains('+') &&
        (normalizedExpression.contains('*') ||
            normalizedExpression.contains('/'));
    if (hasMixedOperators &&
        normalizedExpression.contains('(') &&
        !student.contains('(')) {
      return MistakeType.orderOfOperations;
    }

    return MistakeType.unknown;
  }

  static String _normalize(String? value) =>
      (value ?? '').replaceAll(' ', '').trim();

  static String _extractDenominator(String value) {
    final slashIndex = value.indexOf('/');
    if (slashIndex < 0 || slashIndex == value.length - 1) return '';
    return value.substring(slashIndex + 1);
  }
}
