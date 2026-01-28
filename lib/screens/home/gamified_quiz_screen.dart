import 'package:flutter/material.dart';
import '../../widgets/game_button.dart';
import 'dart:async';

class GamifiedQuizScreen extends StatefulWidget {
  final String questionText;
  final List<OptionItem> options;
  final Function(String answer) onSubmit;
  final int xpReward;

  const GamifiedQuizScreen({
    super.key,
    required this.questionText,
    required this.options,
    required this.onSubmit,
    this.xpReward = 20,
  });

  @override
  State<GamifiedQuizScreen> createState() => _GamifiedQuizScreenState();
}

class _GamifiedQuizScreenState extends State<GamifiedQuizScreen>
    with SingleTickerProviderStateMixin {

  bool answered = false;
  String selectedAnswer = "";
  bool isCorrect = false;

  double questionScale = 1.0;
  double shakeOffset = 0.0;

  bool showXpPopup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 🟦 XP POPUP ANIMACIJA
            if (showXpPopup)
              AnimatedOpacity(
                opacity: showXpPopup ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 22),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.shade400,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "+${widget.xpReward} XP 🎉",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // 🟪 QUESTION CARD SA SCALE + SHAKE EFECTOM
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.identity()
                ..translate(shakeOffset)
                ..scale(questionScale),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blueAccent.shade700,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                widget.questionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            // 🟩 ODGOVORI (GameButton)
            ...widget.options.map((opt) {
              bool correct = answered && opt.isCorrect;
              bool wrong = answered && selectedAnswer == opt.id && !opt.isCorrect;

              return GameButton(
                text: opt.text,
                disabled: answered,
                isCorrect: correct,
                isWrong: wrong,
                onTap: () => _handleAnswer(opt),
              );
            }),

            const Spacer(),

            // 🟨 NEXT QUESTION DUGME
            if (answered)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context, "next");
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        "Next ▶",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  // 🧠 Funkcija: kada klikne odgovor
  void _handleAnswer(OptionItem opt) async {
    setState(() {
      answered = true;
      selectedAnswer = opt.id;
      isCorrect = opt.isCorrect;
    });

    if (isCorrect) {
      _correctAnimation();
    } else {
      _wrongAnimation();
    }

    await Future.delayed(const Duration(milliseconds: 700));

    widget.onSubmit(opt.id);
  }

  // 💚 TAČAN — pulse animacija + XP popup
  void _correctAnimation() {
    setState(() => questionScale = 1.07);

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        questionScale = 1.0;
        showXpPopup = true;
      });
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() => showXpPopup = false);
    });
  }

  // ❤️ NETACAN — shake animacija
  void _wrongAnimation() {
    const values = [-10.0, 10.0, -8.0, 8.0, 0.0];
    int i = 0;

    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      setState(() => shakeOffset = values[i]);
      i++;
      if (i == values.length) {
        timer.cancel();
      }
    });
  }
}

// 📦 Model za opcije (tvoj backend API)
class OptionItem {
  final String id;
  final String text;
  final bool isCorrect;

  OptionItem({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
}
