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
      final colorScheme = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            'Kviz je zavrsen!',
            style: TextStyle(color: colorScheme.onSurface, fontSize: 24),
          ),
        ),
      );
    }

    final question = widget.questions[current];
    return GamifiedQuizScreen(
      question: question,
      questionNumber: current + 1,
      totalQuestions: widget.questions.length,
      options: question.options
          .map(
            (option) => OptionItem(
              id: option.id.toString(),
              text: option.text,
              isCorrect: option.id == question.correctAnswerId,
            ),
          )
          .toList(),
      onSubmit: (answerId) async {
        try {
          await api.submitAnswer('', question.id, answerId, 0, null);
        } catch (_) {}

        if (!mounted) return;
        setState(() {
          current++;
        });
      },
    );
  }
}
