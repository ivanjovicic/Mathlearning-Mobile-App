import 'package:flutter/material.dart';

import '../../../widgets/math/math_renderer.dart';
import '../../../widgets/math/math_view_mode.dart';

class PracticeQuestionCard extends StatelessWidget {
  const PracticeQuestionCard({
    super.key,
    required this.prompt,
    required this.questionNumber,
    required this.totalQuestions,
    this.useGateCopy = false,
  });

  final String prompt;
  final int questionNumber;
  final int totalQuestions;
  final bool useGateCopy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final progressLabel = useGateCopy
        ? 'Gate $questionNumber/$totalQuestions'
        : 'Question $questionNumber of $totalQuestions';

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$progressLabel. $prompt',
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
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (useGateCopy) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    progressLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              MathRenderer(
                value: prompt,
                mode: MathViewMode.questionStem,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
