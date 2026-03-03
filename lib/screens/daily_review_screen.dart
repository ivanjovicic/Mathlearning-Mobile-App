import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_i18n.dart';
import '../state/quiz_provider.dart';
import '../state/progress_provider.dart';
import '../theme/astrax_theme.dart';
import '../widgets/astrax_buttons.dart';
import '../widgets/astrax_card.dart';

class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSrs();
  }

  Future<void> _loadSrs() async {
    final quiz = context.read<QuizProvider>();
    await quiz.loadQuiz();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final qp = Provider.of<QuizProvider>(context);
    final progress = Provider.of<ProgressProvider>(context);
    final questions = qp.questions.take(3).toList();
    final canStart = !_loading && qp.questions.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (_) => false,
                      );
                    },
                    icon: const Icon(Icons.home_outlined, color: Colors.white),
                    tooltip: t.navHome,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Daily Review',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AstraXTheme.neonPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AstraXTheme.neonPurple.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department,
                            color: AstraXTheme.neonPurple,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Streak: ${progress.streak} dana",
                            style: const TextStyle(
                              color: AstraXTheme.neonPurple,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .scale(duration: 300.ms, curve: Curves.easeOutBack)
                    .then()
                    .shimmer(duration: 1400.ms, color: AstraXTheme.neonPurple),
                const SizedBox(height: 12),
                if (_loading)
                  const Text(
                    "Ucitavam pitanja...",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  )
                else
                  Text(
                    "Danas imas ${qp.questions.length} pitanja za ponavljanje.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                const SizedBox(height: 14),
                if (!_loading && !qp.isOnline) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "Offline: koristim poslednja sacuvana SRS pitanja.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 250.ms),
                  const SizedBox(height: 12),
                ],
                if (!_loading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      qp.questions.isEmpty
                          ? (qp.isOnline
                                ? "Danas si sve zavrsio. Bravo!"
                                : "Offline: nema sacuvanih pitanja. Otvori aplikaciju online da preuzmemo Daily Review.")
                          : "Procena: ~${(qp.questions.length * 45 / 60).round().clamp(1, 99)} min",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(duration: 250.ms),
                const SizedBox(height: 30),
                const Icon(Icons.auto_awesome, size: 120, color: Colors.yellow)
                    .animate()
                    .scale(duration: 450.ms, curve: Curves.easeOutBack)
                    .then()
                    .shimmer(duration: 1200.ms, color: Colors.yellowAccent),
                const SizedBox(height: 30),
                if (questions.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(questions.length, (index) {
                      final q = questions[index];
                      return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AstraCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: AstraXTheme.neonGreen,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      q.text,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: (200 + index * 90).ms)
                          .moveY(begin: 12, duration: 350.ms);
                    }),
                  ),
                if (questions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final filled = index < questions.length;
                      return AnimatedContainer(
                        duration: 250.ms,
                        width: filled ? 16 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: filled
                              ? AstraXTheme.neonGreen
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ).animate().fadeIn(duration: 250.ms),
                ],
                const SizedBox(height: 30),
                IgnorePointer(
                  ignoring: !canStart,
                  child: Opacity(
                    opacity: canStart ? 1 : 0.55,
                    child: AstraNeonButton(
                      text: 'Start Review',
                      onTap: () {
                        qp.skipDailyReviewOnce();
                        Navigator.pushReplacementNamed(context, "/quiz");
                      },
                    ),
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                const Text(
                  'Ponavljanje pojacava pamcenje',
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
