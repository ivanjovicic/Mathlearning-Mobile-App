import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_i18n.dart';
import '../../state/quiz_provider.dart';
import '../../state/progress_provider.dart';
import '../../state/settings_provider.dart';
import '../../widgets/gamified_math_panel.dart';
import '../../widgets/game_button.dart';
import '../../widgets/cooldown_circle.dart';
import '../../widgets/mastery_burst.dart';
import '../../widgets/mastery_progress_bar.dart';
import '../../widgets/streak_flame.dart';
import '../../widgets/xp_pop_animation.dart';

class GamifiedQuizScreen extends StatefulWidget {
  final String questionText;
  final List<OptionItem> options;
  final Future<void> Function(String answer) onSubmit;
  final int xpReward;
  final int questionNumber;
  final int totalQuestions;

  const GamifiedQuizScreen({
    super.key,
    required this.questionText,
    required this.options,
    required this.onSubmit,
    required this.questionNumber,
    required this.totalQuestions,
    this.xpReward = 20,
  });

  @override
  State<GamifiedQuizScreen> createState() => _GamifiedQuizScreenState();
}

class _GamifiedQuizScreenState extends State<GamifiedQuizScreen> {
  static const int _noHintBonusXp = 5;

  bool answered = false;
  String selectedAnswer = "";
  bool isCorrect = false;
  bool isSubmitting = false;
  int _combo = 0;
  int _lastBonusXp = 0;

  double questionScale = 1.0;
  double shakeOffset = 0.0;
  OverlayEntry? _xpOverlay;
  OverlayEntry? _streakOverlay;
  OverlayEntry? _masteryOverlay;
  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didUpdateWidget(covariant GamifiedQuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionNumber != widget.questionNumber ||
        oldWidget.questionText != widget.questionText) {
      answered = false;
      selectedAnswer = "";
      isCorrect = false;
      isSubmitting = false;
      questionScale = 1.0;
      shakeOffset = 0.0;
      _lastBonusXp = 0;
      _removeOverlays();
    }
  }

  @override
  void dispose() {
    _removeOverlays();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final quizProvider = Provider.of<QuizProvider>(context);
    final progress = widget.totalQuestions > 0
        ? (widget.questionNumber / widget.totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(theme, colorScheme, progress),
              const SizedBox(height: 20),
              _buildMasteryRow(
                theme: theme,
                colorScheme: colorScheme,
                masteryProgress: quizProvider.masteryPercent,
              ),
              if (_combo > 1) ...[
                const SizedBox(height: 8),
                _buildComboChip(theme, colorScheme, t.comboLabel(_combo)),
              ],
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: _reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                transform:
                    Matrix4.translationValues(shakeOffset, 0.0, 0.0) *
                    Matrix4.diagonal3Values(questionScale, questionScale, 1.0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(
                        (0.12 * 255).round(),
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: GamifiedMathPanel(
                  formula: widget.questionText,
                  title: t.mathChallengeTitle,
                  subtitle: t.mathChallengeSubtitle,
                ),
              ),
              const SizedBox(height: 28),
              ...widget.options.asMap().entries.map((entry) {
                final index = entry.key;
                final opt = entry.value;
                final correct = answered && opt.isCorrect;
                final wrong =
                    answered && selectedAnswer == opt.id && !opt.isCorrect;
                final optionTextColor = correct
                    ? colorScheme.onTertiary
                    : wrong
                    ? colorScheme.onError
                    : colorScheme.onPrimary;

                return GameButton(
                  text: opt.text,
                  disabled: answered || isSubmitting || quizProvider.isCooldown,
                  isCorrect: correct,
                  isWrong: wrong,
                  onTap: () => _handleAnswer(opt),
                  child: _buildOptionContent(
                    theme: theme,
                    colorScheme: colorScheme,
                    option: opt,
                    optionIndex: index,
                    textColor: optionTextColor,
                  ),
                );
              }),
              if (answered) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? colorScheme.tertiaryContainer.withValues(alpha: 0.5)
                        : colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect
                          ? colorScheme.tertiary
                          : colorScheme.error,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect
                            ? colorScheme.tertiary
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect
                            ? _combo > 1
                                  ? "${t.correctXp(widget.xpReward + _lastBonusXp)} - ${t.comboLabel(_combo)}"
                                  : t.correctXp(widget.xpReward + _lastBonusXp)
                            : t.wrongKeepGoing,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCorrect && _lastBonusXp > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.noHintBonus(_lastBonusXp),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              const Spacer(),
              if (quizProvider.isCooldown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Center(child: CooldownCircle(seconds: 1)),
                )
              else if (answered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.questionNumber >= widget.totalQuestions
                                  ? t.finishQuiz
                                  : t.nextQuestion,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    double progress,
  ) {
    final t = context.t;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.questionLabel(widget.questionNumber),
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "${widget.questionNumber}/${widget.totalQuestions}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildMasteryRow({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required double masteryProgress,
  }) {
    final t = context.t;
    final percentage = (masteryProgress * 100).round();
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.masteryLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "$percentage%",
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        MasteryProgressBar(
          progress: masteryProgress,
          animate: !_reduceMotion,
        ),
      ],
    );
  }

  Widget _buildComboChip(
    ThemeData theme,
    ColorScheme colorScheme,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 16,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionContent({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required OptionItem option,
    required int optionIndex,
    required Color textColor,
  }) {
    final optionLabel = String.fromCharCode(65 + optionIndex);
    final isPicked = answered && selectedAnswer == option.id;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.22),
            shape: BoxShape.circle,
            border: Border.all(color: textColor.withValues(alpha: 0.6)),
          ),
          alignment: Alignment.center,
          child: Text(
            optionLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Math.tex(
            option.text,
            textStyle: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            onErrorFallback: (err) => Text(
              option.text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            mathStyle: MathStyle.text,
          ),
        ),
        if (isPicked) ...[
          const SizedBox(width: 8),
          Icon(Icons.auto_awesome, color: textColor, size: 18),
        ],
      ],
    );
  }

  void _handleAnswer(OptionItem opt) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    final awardBonus =
        opt.isCorrect && !quizProvider.usedHintForCurrentQuestion;
    final theme = Theme.of(context);
    final t = context.t;

    _playInteractionFeedback(isCorrect: opt.isCorrect);

    setState(() {
      answered = true;
      selectedAnswer = opt.id;
      isCorrect = opt.isCorrect;
      _combo = opt.isCorrect ? _combo + 1 : 0;
      _lastBonusXp = awardBonus ? _noHintBonusXp : 0;
    });

    final previousMastery = quizProvider.masteryPercent;
    quizProvider.applyMasteryDelta(isCorrect: opt.isCorrect);
    _maybeShowMasteryBurst(
      previous: previousMastery,
      current: quizProvider.masteryPercent,
      theme: theme,
      t: t,
    );

    if (isCorrect) {
      final totalXp = widget.xpReward + _lastBonusXp;
      _showXpPop(
        xp: totalXp,
        backgroundColor: theme.colorScheme.secondary,
        textColor: theme.colorScheme.onSecondary,
        icon: Icons.auto_awesome,
      );
      if (progressProvider.streak > 0) {
        _showStreakFlame(progressProvider.streak);
      }
      _correctAnimation();
    } else {
      _showXpPop(
        xp: 0,
        label: t.tryAgain,
        backgroundColor: theme.colorScheme.errorContainer,
        textColor: theme.colorScheme.onErrorContainer,
        icon: Icons.close,
      );
      _wrongAnimation();
    }
  }

  Future<void> _submitAndContinue() async {
    setState(() {
      isSubmitting = true;
    });

    await widget.onSubmit(selectedAnswer);
    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    // Start cooldown and auto-next
    await _nextQuestionWithCooldown();
  }

  Future<void> _nextQuestionWithCooldown() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    // Wait 1 second for cooldown
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Move to next question
    quizProvider.goToNextQuestion();
  }

  void _showXpPop({
    required int xp,
    String? label,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
  }) {
    if (_reduceMotion) return;
    _xpOverlay?.remove();
    _xpOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 120,
        right: 20,
        child: IgnorePointer(
          child: XpPopAnimation(
            xp: xp,
            label: label,
            backgroundColor: backgroundColor,
            textColor: textColor,
            icon: icon,
            reduceMotion: _reduceMotion,
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_xpOverlay!);
    Future.delayed(const Duration(milliseconds: 900), () {
      _xpOverlay?.remove();
      _xpOverlay = null;
    });
  }

  void _showStreakFlame(int streak) {
    if (_reduceMotion) return;
    _streakOverlay?.remove();
    _streakOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 140,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(child: StreakFlame(streak: streak)),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_streakOverlay!);
    Future.delayed(const Duration(milliseconds: 650), () {
      _streakOverlay?.remove();
      _streakOverlay = null;
    });
  }

  void _maybeShowMasteryBurst({
    required double previous,
    required double current,
    required ThemeData theme,
    required AppI18n t,
  }) {
    if (_reduceMotion) return;
    if (previous < 0.5 && current >= 0.5) {
      _showMasteryBurst(
        label: t.masteryMilestone(50),
        color: theme.colorScheme.tertiary,
      );
    }
    if (previous < 1.0 && current >= 1.0) {
      _showMasteryBurst(
        label: t.masteryMax,
        color: theme.colorScheme.primary,
      );
    }
  }

  void _showMasteryBurst({
    required String label,
    required Color color,
  }) {
    _masteryOverlay?.remove();
    _masteryOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 90,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: MasteryBurst(
              label: label,
              color: color,
              reduceMotion: _reduceMotion,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_masteryOverlay!);
    Future.delayed(const Duration(milliseconds: 700), () {
      _masteryOverlay?.remove();
      _masteryOverlay = null;
    });
  }

  void _removeOverlays() {
    _xpOverlay?.remove();
    _xpOverlay = null;
    _streakOverlay?.remove();
    _streakOverlay = null;
    _masteryOverlay?.remove();
    _masteryOverlay = null;
  }

  void _correctAnimation() {
    if (_reduceMotion) {
      setState(() {
        questionScale = 1.0;
      });
      return;
    }

    setState(() => questionScale = 1.07);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        questionScale = 1.0;
      });
    });
  }

  void _wrongAnimation() {
    if (_reduceMotion) {
      setState(() {
        shakeOffset = 0.0;
      });
      return;
    }

    const values = [-10.0, 10.0, -8.0, 8.0, 0.0];
    var i = 0;

    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => shakeOffset = values[i]);
      i++;
      if (i == values.length) {
        timer.cancel();
      }
    });
  }

  void _playInteractionFeedback({required bool isCorrect}) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
    if (settings.vibrationEnabled) {
      if (isCorrect) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
  }
}

class OptionItem {
  final String id;
  final String text;
  final bool isCorrect;

  OptionItem({required this.id, required this.text, required this.isCorrect});
}
