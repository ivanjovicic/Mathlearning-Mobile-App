import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/quiz_provider.dart';
import '../state/progress_provider.dart';
import '../state/coin_provider.dart';
import '../models/question.dart';
import '../models/option.dart';
import '../models/hint_models.dart';
import '../widgets/level_up_animation.dart';
import '../widgets/hint_button.dart';
import '../widgets/clue_hint_bubble.dart';
import '../widgets/animated_answer_option.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int selectedIndex = -1;
  bool answered = false;
  bool isCorrect = false;
  bool _quizStarted = false; // Flag to prevent multiple starts

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // Animations for question transitions
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_controller);
    _slideAnim = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(_controller);

    // Set up level-up callback for progress provider
    Future.microtask(() {
      if (mounted) {
        final progress = Provider.of<ProgressProvider>(context, listen: false);
        final coinProvider = Provider.of<CoinProvider>(context, listen: false);
        
        // Load coins and hints data
        coinProvider.loadCoinsAndHints();
        
        progress.onLevelUp = () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => LevelUpAnimation(
              level: progress.level,
              onFinished: () {
                Navigator.pop(context);
              },
            ),
          );
        };
      }
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      _controller.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Start quiz automatically when screen loads
    if (!_quizStarted) {
      _quizStarted = true;
      _startQuiz();
    }
  }

  Future<void> _startQuiz() async {
    // Get topic ID from route arguments
    final topicId = ModalRoute.of(context)?.settings.arguments as int? ?? 1;
    
    final quiz = Provider.of<QuizProvider>(context, listen: false);
    
    debugPrint('🎯 Starting quiz for topic: $topicId');
    
    final success = await quiz.startQuiz(topicId, 10); // Start quiz with 10 questions
    
    if (!success) {
      debugPrint('❌ Failed to start quiz, using demo questions');
      // Show error or fallback to demo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using demo questions - backend not available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      debugPrint('✅ Quiz started successfully');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void onOptionSelected(QuizProvider quiz, Question q, Option option, int index) async {
    if (answered) return;

    setState(() {
      selectedIndex = index;
      answered = true;
      isCorrect = (option.id == q.correctAnswerId);  // for animation only
    });

    // haptic feedback
    if (isCorrect) {
      Feedback.forTap(context);
    } else {
      Feedback.forLongPress(context);
    }

    // XP popup delay
    await Future.delayed(const Duration(milliseconds: 900));

    // send answer to backend
    await quiz.answer(option.text, context);

    // reset UI
    setState(() {
      selectedIndex = -1;
      answered = false;
    });

    // play animation
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = Provider.of<QuizProvider>(context);
    final q = quiz.currentQuestion;

    if (q == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: coins, progress, XP, question number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Coins display
                  Consumer<CoinProvider>(
                    builder: (context, coinProvider, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade400,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on, size: 16, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              '${coinProvider.coins}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  Row(
                    children: [
                      Text(
                        "⭐ XP +5",
                        style: TextStyle(
                          color: Colors.yellow.shade300,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Question",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Hint buttons
              if (!answered) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    HintButton(
                      hintType: HintType.formula,
                      icon: Icons.functions,
                      label: 'Formula',
                      isLoading: quiz.isLoadingHint,
                      onPressed: () => quiz.showFormulaHint(context),
                    ),
                    HintButton(
                      hintType: HintType.clue,
                      icon: Icons.tips_and_updates,
                      label: 'Clue',
                      isLoading: quiz.isLoadingHint,
                      onPressed: () => quiz.showClueHint(context),
                    ),
                    HintButton(
                      hintType: HintType.eliminate,
                      icon: Icons.remove_circle,
                      label: 'Eliminate',
                      isLoading: quiz.isLoadingHint,
                      onPressed: () => quiz.eliminateWrongOption(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Clue hint bubble
              if (quiz.currentClue != null && !answered)
                Center(
                  child: ClueHintBubble(
                    clue: quiz.currentClue!,
                    show: true,
                  ),
                ),
              if (quiz.currentClue != null && !answered)
                const SizedBox(height: 16),

              // Question text with animation
              SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    q.text,
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Options
              Expanded(
                child: ListView.separated(
                  itemCount: q.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = q.options[index];
                    final bool isSelected = index == selectedIndex;
                    final bool isEliminated = quiz.eliminatedOptions.contains(option.id.toString());

                    return AnimatedAnswerOption(
                      text: option.text,
                      isEliminated: isEliminated,
                      isSelected: isSelected,
                      onTap: () => onOptionSelected(quiz, q, option, index),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
