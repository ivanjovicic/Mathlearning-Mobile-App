import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../services/api_service.dart';
import 'gamified_quiz_screen.dart';

class GamifiedQuizFlow extends StatefulWidget {
  final List<Question> questions;
  final int startIndex;

  const GamifiedQuizFlow({
    super.key,
    required this.questions,
    this.startIndex = 0,
  });

  @override
  State<GamifiedQuizFlow> createState() => _GamifiedQuizFlowState();
}

class _GamifiedQuizFlowState extends State<GamifiedQuizFlow> {
  int current = 0;
  late ApiService api;

  @override
  void initState() {
    super.initState();
    api = ApiService();
    current = widget.startIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (current >= widget.questions.length) {
      return Scaffold(
        backgroundColor: const Color(0xFF101820),
        body: Center(
          child: Text(
            'Quiz finished!',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      );
    }
    final question = widget.questions[current];
    return GamifiedQuizScreen(
      questionText: question.text,
      options: question.options
          .map(
            (o) => OptionItem(
              id: o.id.toString(),
              text: o.text,
              isCorrect: false, // backend NE šalje correct ovde
            ),
          )
          .toList(),
      onSubmit: (answerId) async {
        // Submit answer to backend when possible. We don't have quizId here,
        // so supply empty quizId and 0 timeSpentSeconds as placeholders.
        try {
          await api.submitAnswer('', question.id, answerId, 0, null);
        } catch (_) {}

        setState(() {
          current++;
        });
      },
    );
  }
}
