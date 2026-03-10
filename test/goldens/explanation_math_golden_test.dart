import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/models/step_explanation.dart';
import 'package:mathlearning/widgets/explanations/mistake_explanation_card.dart';
import 'package:mathlearning/widgets/explanations/step_explanation_card.dart';
import 'package:mathlearning/widgets/explanations/step_explanation_controller.dart';

void main() {
  testWidgets('explanation math golden 320 width', (tester) async {
    await _pumpExplanationSurface(tester, const Size(320, 760));
    await expectLater(
      find.byKey(const ValueKey<String>('explanation-math-golden')),
      matchesGoldenFile('goldens/explanation_math_320.png'),
    );
  });

  testWidgets('explanation math golden 390 width', (tester) async {
    await _pumpExplanationSurface(tester, const Size(390, 844));
    await expectLater(
      find.byKey(const ValueKey<String>('explanation-math-golden')),
      matchesGoldenFile('goldens/explanation_math_390.png'),
    );
  });

  testWidgets('explanation math golden tablet width', (tester) async {
    await _pumpExplanationSurface(tester, const Size(1024, 768));
    await expectLater(
      find.byKey(const ValueKey<String>('explanation-math-golden')),
      matchesGoldenFile('goldens/explanation_math_tablet.png'),
    );
  });
}

Future<void> _pumpExplanationSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          disableAnimations: true,
          textScaler: const TextScaler.linear(1.3),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8FB),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: RepaintBoundary(
                key: const ValueKey<String>('explanation-math-golden'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      StepExplanationCard(
                        step: StepExplanation(
                          text:
                              r'Factor the equation into $(x-1)(x-2)=0$ and solve each factor.',
                          hint: r'Zero-product rule: if $ab=0$, then $a=0$ or $b=0$.',
                          highlight: true,
                        ),
                        stepNumber: 2,
                        totalSteps: 3,
                        isHintVisible: true,
                        onHintToggle: _noop,
                      ),
                      SizedBox(height: 16),
                      MistakeExplanationCard(
                        explanation:
                            r'You simplified $\frac{1}{2}+\frac{1}{3}$ directly to $\frac{2}{5}$ instead of finding a common denominator.',
                        misconception:
                            r'Fractions require a shared denominator before addition.',
                        mistakeType: MistakeType.denominatorError,
                        studentAnswer: r'\frac{2}{5}',
                        expectedAnswer: r'\frac{5}{6}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void _noop() {}
