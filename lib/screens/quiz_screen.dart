import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/quiz_provider.dart';
import '../models/question.dart';
import 'home/gamified_quiz_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool loading = true;
  Question? currentQuestion;
  int? subtopicId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loading) {
      subtopicId = ModalRoute.of(context)?.settings.arguments as int? ?? 1;
      _startQuiz();
    }
  }

  Future<void> _startQuiz() async {
    final quiz = Provider.of<QuizProvider>(context, listen: false);
    final success = await quiz.startQuiz(subtopicId!, 10);
    if (success && quiz.currentQuestion != null) {
      setState(() {
        currentQuestion = quiz.currentQuestion;
        loading = false;
      });
    } else {
      // fallback UI
      setState(() {
        loading = false;
      });
    }
  }

  void _showGamifiedQuestion(Question question) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GamifiedQuizScreen(
          questionText: question.text,
          options: question.options
              .map(
                (o) => OptionItem(
                  id: o.id.toString(),
                  text: o.text,
                  isCorrect: false,
                ),
              )
              .toList(),
          onSubmit: (answerId) async {
            final quiz = Provider.of<QuizProvider>(context, listen: false);
            await quiz.answer(answerId, context);
            final next = quiz.currentQuestion;
            if (next != null) {
              _showGamifiedQuestion(next);
            } else {
              Navigator.pushReplacementNamed(context, '/quiz_result');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101820),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (currentQuestion != null) {
      // Prikazujemo prvo pitanje kroz GamifiedQuizScreen
      Future.microtask(() => _showGamifiedQuestion(currentQuestion!));
      return const SizedBox.shrink();
    }
    return const Scaffold(
      backgroundColor: Color(0xFF101820),
      body: Center(
        child: Text(
          'No questions available',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
