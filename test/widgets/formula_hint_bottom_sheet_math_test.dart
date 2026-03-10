import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mathlearning/models/step_explanation.dart';
import 'package:mathlearning/state/settings_provider.dart';
import 'package:mathlearning/widgets/formula_hint_bottom_sheet.dart';

void main() {
  testWidgets('renders step explanations with math in bottom sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) => SettingsProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: FormulaHintBottomSheet(
              steps: <StepExplanation>[
                const StepExplanation(text: r'Compute $x^2$ first.'),
                const StepExplanation(text: r'\frac{-b\pm\sqrt{b^2-4ac}}{2a}'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsWidgets);

    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();

    expect(find.byType(Math), findsWidgets);
  });
}
