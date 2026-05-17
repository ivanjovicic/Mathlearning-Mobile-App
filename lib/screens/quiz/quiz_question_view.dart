import 'package:flutter/material.dart';
import '../../l10n/app_i18n.dart';
import '../../theme/astrax_theme.dart';
import '../../widgets/astrax_buttons.dart';
import '../../widgets/astrax_card.dart';
import '../../widgets/astrax_xp_bar.dart';
import '../../widgets/math/math_renderer.dart';
import '../../widgets/math/math_view_mode.dart';

class QuizQuestionView extends StatelessWidget {
  final String questionText;
  final List<String> answers;
  final int? selectedIndex;
  final int? correctIndex;
  final VoidCallback onNext;
  final ValueChanged<int> onAnswer;

  const QuizQuestionView({
    super.key,
    required this.questionText,
    required this.answers,
    required this.onNext,
    required this.onAnswer,
    this.selectedIndex,
    this.correctIndex,
  });

  @override
  Widget build(BuildContext context) {
    final showResult = correctIndex != null && selectedIndex != null;
    final t = context.t;

    return Scaffold(
      backgroundColor: AstraXTheme.bg,
      appBar: AppBar(
        title: Text(t.quizQuickTitle),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            AstraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.quizQuestionLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  MathRenderer(
                    value: questionText,
                    mode: MathViewMode.questionStem,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.separated(
                itemCount: answers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final text = answers[index];
                  Color border = Colors.white12;
                  Color bg = AstraXTheme.panelLight;
                  IconData? icon;
                  Color? iconColor;

                  if (showResult) {
                    if (index == correctIndex) {
                      border = AstraXTheme.neonGreen;
                      bg = Colors.white10;
                      icon = Icons.check_circle_rounded;
                      iconColor = AstraXTheme.neonGreen;
                    } else if (index == selectedIndex &&
                        selectedIndex != correctIndex) {
                      border = AstraXTheme.danger;
                      bg = Colors.white10;
                      icon = Icons.cancel_rounded;
                      iconColor = AstraXTheme.danger;
                    }
                  } else if (selectedIndex == index) {
                    border = AstraXTheme.neonBlue;
                    bg = Colors.white10;
                  }

                  return GestureDetector(
                    onTap: showResult ? null : () => onAnswer(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: border, width: 1.3),
                      ),
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: iconColor, size: 20),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: MathRenderer(
                              value: text,
                              mode: MathViewMode.answerOption,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            AstraXPBar(progress: 0.4, label: t.quizXpProgress),
            const SizedBox(height: 14),
            AstraNeonButton(
              text: showResult ? t.quizNext : t.quizConfirm,
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}
