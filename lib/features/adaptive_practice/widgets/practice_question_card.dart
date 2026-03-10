import 'package:flutter/material.dart';

import '../../../widgets/math/math_renderer.dart';
import '../../../widgets/math/math_view_mode.dart';

class PracticeQuestionCard extends StatelessWidget {
  const PracticeQuestionCard({
    super.key,
    required this.prompt,
    required this.questionNumber,
    required this.totalQuestions,
  });

  final String prompt;
  final int questionNumber;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Question $questionNumber of $totalQuestions. $prompt',
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
          child: Container(
            key: ValueKey<String>('question_$questionNumber$prompt'),
            width: double.infinity,
            padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: MathRenderer(
            value: prompt,
            mode: MathViewMode.questionStem,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
