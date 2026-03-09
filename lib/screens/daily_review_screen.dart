import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_i18n.dart';
import '../state/quiz_provider.dart';
import '../state/progress_provider.dart';
import '../theme/app_scale.dart';
import '../theme/astrax_theme.dart';
import '../theme/tokens/spacing_tokens.dart';
import '../widgets/astrax_buttons.dart';
import '../widgets/astrax_card.dart';
import '../widgets/ui/state_scaffold.dart';

class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadSrs();
    });
  }

  Future<void> _loadSrs() async {
    try {
      final quiz = context.read<QuizProvider>();
      await quiz.loadQuiz();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final qp = Provider.of<QuizProvider>(context);
    final progress = Provider.of<ProgressProvider>(context);
    final questions = qp.questions.take(3).toList();
    final canStart = !_loading && qp.questions.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: StateScaffold(
          isLoading: _loading,
          error: _error,
          onRetry: _loadSrs,
          isEmpty: !_loading && _error == null && qp.questions.isEmpty,
          emptyTitle: "Nema pitanja za danas",
          emptySubtitle: "Odlicno, sve je uradjeno. Vrati se kasnije.",
          emptyIcon: Icons.check_circle_outline,
          child: Center(
            child: ConstrainedBox(
              constraints: AppScale.centeredContentConstraints(),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: SingleChildScrollView(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        context.go('/home');
                      },
                      icon: Icon(
                        Icons.home_outlined,
                        color: Colors.white,
                        size: AppScale.icon(24, min: 22, max: 32),
                      ),
                      tooltip: t.navHome,
                    ),
                  ),
                  SizedBox(height: AppScale.s(40)),
                  Text(
                    'Daily Review',
                    style: TextStyle(
                      fontSize: AppScale.font(32, min: 26, max: 40),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AstraXTheme.neonPurple.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppScale.radius(18),
                          ),
                          border: Border.all(
                            color: AstraXTheme.neonPurple.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: AstraXTheme.neonPurple,
                              size: AppScale.icon(18, min: 16, max: 24),
                            ),
                            SizedBox(width: AppSpacing.xs + AppSpacing.sm / 4),
                            Text(
                              "Streak: ${progress.streak} dana",
                              style: TextStyle(
                                color: AstraXTheme.neonPurple,
                                fontWeight: FontWeight.w700,
                                fontSize: AppScale.font(13, min: 12, max: 18),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .scale(duration: 300.ms, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(
                        duration: 1400.ms,
                        color: AstraXTheme.neonPurple,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    "Danas imas ${qp.questions.length} pitanja za ponavljanje.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppScale.font(18, min: 16, max: 24),
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: AppScale.s(14)),
                  if (!_loading && !qp.isOnline) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppScale.s(14),
                        vertical: AppScale.s(10),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppScale.radius(14),
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            color: Colors.white70,
                            size: AppScale.icon(16, min: 14, max: 22),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              "Offline: koristim poslednja sacuvana SRS pitanja.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: AppScale.font(13, min: 12, max: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 250.ms),
                    SizedBox(height: AppSpacing.md),
                  ],
                  if (!_loading)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppScale.s(14),
                        vertical: AppScale.s(6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppScale.radius(16),
                        ),
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
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: AppScale.font(13, min: 12, max: 18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate().fadeIn(duration: 250.ms),
                  SizedBox(height: AppScale.s(30)),
                  Icon(
                        Icons.auto_awesome,
                        size: AppScale.icon(120, min: 88, max: 160),
                        color: Colors.yellow,
                      )
                      .animate()
                      .scale(duration: 450.ms, curve: Curves.easeOutBack)
                      .then()
                      .shimmer(duration: 1200.ms, color: Colors.yellowAccent),
                  SizedBox(height: AppScale.s(30)),
                  if (questions.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(questions.length, (index) {
                        final q = questions[index];
                        return Padding(
                              padding: EdgeInsets.only(bottom: AppScale.s(10)),
                              child: AstraCard(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppScale.s(14),
                                  vertical: AppScale.s(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: AstraXTheme.neonGreen,
                                      size: AppScale.icon(20, min: 18, max: 28),
                                    ),
                                    SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        q.text,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: AppScale.font(
                                            14,
                                            min: 13,
                                            max: 20,
                                          ),
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
                    SizedBox(height: AppSpacing.xs + AppSpacing.sm / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final filled = index < questions.length;
                        return AnimatedContainer(
                          duration: 250.ms,
                          width: filled ? AppScale.s(16) : AppScale.s(8),
                          height: AppScale.s(8),
                          margin: EdgeInsets.symmetric(horizontal: AppScale.s(4)),
                          decoration: BoxDecoration(
                            color: filled
                                ? AstraXTheme.neonGreen
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(
                              AppScale.radius(10),
                            ),
                          ),
                        );
                      }),
                    ).animate().fadeIn(duration: 250.ms),
                  ],
                  SizedBox(height: AppScale.s(30)),
                  IgnorePointer(
                    ignoring: !canStart,
                    child: Opacity(
                      opacity: canStart ? 1 : 0.55,
                      child: AstraNeonButton(
                        text: 'Start Review',
                        onTap: () {
                          qp.skipDailyReviewOnce();
                          context.go('/quiz');
                        },
                      ),
                    ),
                  ).animate().scale(
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
                  SizedBox(height: AppSpacing.lg),
                  Text(
                    'Ponavljanje pojacava pamcenje',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: AppScale.font(13, min: 12, max: 18),
                    ),
                  ),
                  SizedBox(height: AppScale.s(30)),
                ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
