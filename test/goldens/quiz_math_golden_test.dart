import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/widgets/math/math_renderer.dart';
import 'package:mathlearning/widgets/math/math_view_mode.dart';
import 'package:mathlearning/widgets/ui/answer_option_card.dart';

void main() {
  testWidgets('quiz math golden 320 width', (tester) async {
    await _pumpQuizSurface(tester, const Size(320, 720));
    await expectLater(
      find.byKey(const ValueKey<String>('quiz-math-golden')),
      matchesGoldenFile('goldens/quiz_math_320.png'),
    );
  });

  testWidgets('quiz math golden 390 width', (tester) async {
    await _pumpQuizSurface(tester, const Size(390, 844));
    await expectLater(
      find.byKey(const ValueKey<String>('quiz-math-golden')),
      matchesGoldenFile('goldens/quiz_math_390.png'),
    );
  });

  testWidgets('quiz math golden tablet width', (tester) async {
    await _pumpQuizSurface(tester, const Size(1024, 768));
    await expectLater(
      find.byKey(const ValueKey<String>('quiz-math-golden')),
      matchesGoldenFile('goldens/quiz_math_tablet.png'),
    );
  });
}

Future<void> _pumpQuizSurface(WidgetTester tester, Size size) async {
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
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F8FB),
          body: Center(
            child: RepaintBoundary(
              key: const ValueKey<String>('quiz-math-golden'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(18),
                          child: MathRenderer(
                            value:
                                r'Compute $\frac{-b\pm\sqrt{b^2-4ac}}{2a}$ when $a=1$, $b=-3$, and $c=2$.',
                            mode: MathViewMode.questionStem,
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      AnswerOptionCard(
                        text: r'x=\frac{3+\sqrt{1}}{2}',
                        selected: true,
                      ),
                      SizedBox(height: 10),
                      AnswerOptionCard(
                        text: r'x=\frac{3-\sqrt{1}}{2}',
                        selected: false,
                      ),
                      SizedBox(height: 10),
                      AnswerOptionCard(
                        text: r'Both $x=1$ and $x=2$',
                        selected: false,
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
