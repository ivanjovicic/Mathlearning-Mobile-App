import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_i18n.dart';
import '../../state/quiz_provider.dart';
import '../../state/progress_provider.dart';
import '../../state/settings_provider.dart';
import '../../theme/app_scale.dart';
import '../../theme/tokens/spacing_tokens.dart';
import '../../utils/overlay_safety.dart';
import '../../widgets/gamified_math_panel.dart';
import '../../widgets/game_button.dart';
import '../../widgets/cooldown_circle.dart';
import '../../widgets/mastery_burst.dart';
import '../../widgets/mastery_progress_bar.dart';
import '../../widgets/streak_flame.dart';
import '../../widgets/xp_pop_animation.dart';
import '../../widgets/formula_hint_bottom_sheet.dart';
import '../../widgets/explanations/mistake_explanation_card.dart';
import '../../widgets/explanations/step_explanation_controller.dart';
import '../../widgets/math_content_text.dart';

import '../../models/question.dart';

class GamifiedQuizScreen extends StatefulWidget {
  final Question question;
  final List<OptionItem> options;
  final Future<void> Function(String answer) onSubmit;
  final int xpReward;
  final int questionNumber;
  final int totalQuestions;

  const GamifiedQuizScreen({
    super.key,
    required this.question,
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
  int _awardedXpPreview = 0;

  double questionScale = 1.0;
  double shakeOffset = 0.0;
  OverlayEntry? _xpOverlay;
  OverlayEntry? _streakOverlay;
  OverlayEntry? _masteryOverlay;
  OverlayState? _rootOverlayOrNull() =>
      Overlay.maybeOf(context, rootOverlay: true);
  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didUpdateWidget(covariant GamifiedQuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questionNumber != widget.questionNumber ||
        oldWidget.question.id != widget.question.id) {
      answered = false;
      selectedAnswer = "";
      isCorrect = false;
      isSubmitting = false;
      questionScale = 1.0;
      shakeOffset = 0.0;
      _lastBonusXp = 0;
      _awardedXpPreview = 0;
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final isLandscape = width > height;
            final columns = isLandscape ? 2 : 1;
            final horizontalPadding = AppScale.s(18).clamp(12.0, 40.0).toDouble();
            final topGap = AppScale.s(14).clamp(10.0, 22.0).toDouble();
            final betweenHeaderGap = AppScale.s(8).clamp(6.0, 14.0).toDouble();
            final sectionGap = AppScale.s(12).clamp(10.0, 18.0).toDouble();

            final questionCardPadding = EdgeInsets.all(AppScale.s(18));
            final afterQuestionGap = AppScale.s(24).clamp(18.0, 32.0).toDouble();

            final optionSpacing = AppScale.s(10).clamp(8.0, 16.0).toDouble();
            final optionPadding = EdgeInsets.symmetric(
              vertical: AppScale.s(12).clamp(10.0, 18.0).toDouble(),
              horizontal: AppScale.s(16).clamp(14.0, 24.0).toDouble(),
            );

            final optionDensity = (0.95 + (AppScale.scale - 1) * 0.15)
                .clamp(0.92, 1.08)
                .toDouble();

            final questionFontSize = AppScale.font(
              24,
              min: 18,
              max: 36,
            );

            final questionExpressionStyle =
                theme.textTheme.headlineSmall?.copyWith(
                  fontSize: questionFontSize,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  letterSpacing: 0.3,
                ) ??
                TextStyle(
                  fontSize: questionFontSize,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                  letterSpacing: 0.3,
                );

            final optionFontSize = AppScale.font(18, min: 16, max: 22);

            Widget buildQuestionCard() {
              return AnimatedContainer(
                duration: _reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                transform:
                    Matrix4.translationValues(shakeOffset, 0.0, 0.0) *
                    Matrix4.diagonal3Values(questionScale, questionScale, 1.0),
                padding: questionCardPadding,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(AppScale.radius(18)),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(
                        (0.12 * 255).round(),
                      ),
                      blurRadius: AppScale.s(20),
                      offset: Offset(0, AppScale.s(5)),
                    ),
                  ],
                ),
                child: GamifiedMathPanel(
                  formula: widget.question.text,
                  title: t.mathChallengeTitle,
                  subtitle: t.mathChallengeSubtitle,
                  expressionTextStyle: questionExpressionStyle,
                ),
              );
            }

            Widget buildOptionButton(int index) {
              final opt = widget.options[index];
              final correct = answered && opt.isCorrect;
              final wrong =
                  answered && selectedAnswer == opt.id && !opt.isCorrect;
              final optionTextColor = correct
                  ? colorScheme.onTertiary
                  : wrong
                  ? colorScheme.onError
                  : colorScheme.onPrimary;

              final optionTextStyle =
                  theme.textTheme.bodyLarge?.copyWith(
                    fontSize: optionFontSize * optionDensity,
                    fontWeight: FontWeight.bold,
                    color: optionTextColor,
                  ) ??
                  TextStyle(
                    fontSize: optionFontSize * optionDensity,
                    fontWeight: FontWeight.bold,
                    color: optionTextColor,
                  );

              return GameButton(
                text: opt.text,
                padding: optionPadding,
                margin: EdgeInsets.zero,
                disabled:
                    answered ||
                    isSubmitting ||
                    quizProvider.isCooldown ||
                    quizProvider.isSubmittingAnswer,
                isCorrect: correct,
                isWrong: wrong,
                onTap: () => _handleAnswer(opt),
                child: _buildOptionContent(
                  theme: theme,
                  colorScheme: colorScheme,
                  option: opt,
                  optionIndex: index,
                  textColor: optionTextColor,
                  density: optionDensity,
                  optionTextStyle: optionTextStyle,
                ),
              );
            }

            SliverPadding buildOptionsSliver({required double topPadding}) {
              if (columns == 1) {
                // In 1-column layouts we want option cards to size to content
                // instead of being forced to a tall fixed grid height.
                return SliverPadding(
                  padding: EdgeInsets.only(top: topPadding, bottom: AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index == widget.options.length - 1
                              ? 0
                              : optionSpacing,
                        ),
                        child: buildOptionButton(index),
                      ),
                      childCount: widget.options.length,
                    ),
                  ),
                );
              }

              final ratio = (3.0 - ((AppScale.scale - 1) * 0.25))
                  .clamp(2.4, 3.0)
                  .toDouble();
              return SliverPadding(
                padding: EdgeInsets.only(top: topPadding, bottom: AppSpacing.md),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: optionSpacing,
                    crossAxisSpacing: optionSpacing,
                    childAspectRatio: ratio,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => buildOptionButton(index),
                    childCount: widget.options.length,
                  ),
                ),
              );
            }

            final body = isLandscape
                ? Row(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          key: ValueKey('quiz_left_${widget.question.id}'),
                          slivers: [
                            SliverToBoxAdapter(child: buildQuestionCard()),
                            SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.md),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: AppScale.s(24).clamp(16.0, 36.0).toDouble(),
                      ),
                      Expanded(
                        child: CustomScrollView(
                          key: ValueKey('quiz_right_${widget.question.id}'),
                          slivers: [
                            buildOptionsSliver(topPadding: 0),
                            SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.md),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(
                    key: ValueKey('quiz_portrait_${widget.question.id}'),
                    slivers: [
                      SliverToBoxAdapter(child: buildQuestionCard()),
                      buildOptionsSliver(topPadding: afterQuestionGap),
                      SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
                    ],
                  );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isLandscape ? 920 : AppScale.maxContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      SizedBox(height: topGap),
                      _buildHeader(theme, colorScheme, progress),
                      SizedBox(height: betweenHeaderGap),
                      _buildMasteryRow(
                        theme: theme,
                        colorScheme: colorScheme,
                        masteryProgress: quizProvider.masteryPercent,
                      ),
                      if (_combo > 1) ...[
                        SizedBox(height: betweenHeaderGap),
                        _buildComboChip(
                          theme,
                          colorScheme,
                          t.comboLabel(_combo),
                        ),
                      ],
                      SizedBox(height: sectionGap),
                      Expanded(child: body),
                      if (answered) ...[
                        SizedBox(height: AppScale.s(10)),
                        _buildAnswerFeedback(
                          theme: theme,
                          colorScheme: colorScheme,
                          t: t,
                        ),
                        SizedBox(height: AppSpacing.md),
                      ],
                      if (quizProvider.isCooldown)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          child: const Center(child: CooldownCircle(seconds: 1)),
                        )
                      else if (answered)
                        Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: AppScale.maxContentWidth,
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      (isSubmitting ||
                                          quizProvider.isSubmittingAnswer)
                                      ? null
                                      : _submitAndContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppScale.s(14),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppScale.radius(14),
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isSubmitting
                                      ? SizedBox(
                                          height: AppScale.s(20),
                                          width: AppScale.s(20),
                                          child: CircularProgressIndicator(
                                            strokeWidth: AppScale.s(2),
                                          ),
                                        )
                                      : Text(
                                          widget.questionNumber >=
                                                  widget.totalQuestions
                                              ? t.finishQuiz
                                              : t.nextQuestion,
                                          style: TextStyle(
                                            fontSize: AppScale.font(
                                              17,
                                              min: 15,
                                              max: 22,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
          },
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
            Row(
              children: [
                // Hint button
                IconButton(
                  icon: Icon(
                    Icons.lightbulb_outline,
                    color: colorScheme.primary,
                  ),
                  onPressed: answered ? null : _showHintModal,
                  tooltip: context.safeTooltip(t.hint),
                ),
                const SizedBox(width: 8),
                Text(
                  "${widget.questionNumber}/${widget.totalQuestions}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
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
        MasteryProgressBar(progress: masteryProgress, animate: !_reduceMotion),
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

  Widget _buildAnswerFeedback({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required AppI18n t,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isCorrect
                ? colorScheme.tertiaryContainer
                : colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCorrect
                  ? colorScheme.tertiary.withValues(alpha: 0.75)
                  : colorScheme.error.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isCorrect
                      ? _combo > 1
                            ? '${t.correctXp(_awardedXpPreview)} - ${t.comboLabel(_combo)}'
                            : t.correctXp(_awardedXpPreview)
                      : t.wrongKeepGoing,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCorrect
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isCorrect && _lastBonusXp > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  t.noHintBonus(_lastBonusXp),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (!isCorrect) ...[
          const SizedBox(height: 10),
          MistakeExplanationCard(
            explanation: _resolveMistakeExplanation(),
            misconception: _resolveCommonMisconception(),
            mistakeType: _resolveMistakeTypeForFeedback(),
            studentAnswer: _resolveSelectedOptionText(),
            expectedAnswer: _resolveCorrectOptionText(),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionContent({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required OptionItem option,
    required int optionIndex,
    required Color textColor,
    required double density,
    required TextStyle optionTextStyle,
  }) {
    final optionLabel = String.fromCharCode(65 + optionIndex);
    final isPicked = answered && selectedAnswer == option.id;
    final circle = 28.0 * density;
    final gap = 10.0 * density;
    final pickedGap = 8.0 * density;
    final pickedIcon = 18.0 * density;

    return Row(
      children: [
        Container(
          width: circle,
          height: circle,
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
              fontSize: 14.0 * density,
            ),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _buildOptionExpression(
            theme: theme,
            rawValue: option.text,
            textColor: textColor,
            textStyle: optionTextStyle,
          ),
        ),
        if (isPicked) ...[
          SizedBox(width: pickedGap),
          Icon(Icons.auto_awesome, color: textColor, size: pickedIcon),
        ],
      ],
    );
  }

  void _handleAnswer(OptionItem opt) {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final progressProvider = Provider.of<ProgressProvider>(
      context,
      listen: false,
    );
    final canAwardXp = quizProvider.canAwardXpForQuestion(widget.question);
    final awardBonus =
        opt.isCorrect && !quizProvider.usedHintForCurrentQuestion && canAwardXp;
    final awardedXp = opt.isCorrect
        ? (canAwardXp ? widget.xpReward + (awardBonus ? _noHintBonusXp : 0) : 0)
        : 0;
    final theme = Theme.of(context);
    final t = context.t;

    _playInteractionFeedback(isCorrect: opt.isCorrect);

    setState(() {
      answered = true;
      selectedAnswer = opt.id;
      isCorrect = opt.isCorrect;
      _combo = opt.isCorrect ? _combo + 1 : 0;
      _lastBonusXp = awardBonus ? _noHintBonusXp : 0;
      _awardedXpPreview = awardedXp;
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
      final totalXp = _awardedXpPreview;
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

  Widget _buildOptionExpression({
    required ThemeData theme,
    required String rawValue,
    required Color textColor,
    TextStyle? textStyle,
  }) {
    final value = _normalizeInlineMathDelimiters(rawValue.trim());
    final effectiveTextStyle =
        (textStyle ??
            theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.3,
            )) ??
        TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.3,
        );

    if (_hasInlineMathSegments(value)) {
      return _buildInlineOptionText(
        value: value,
        textStyle: effectiveTextStyle,
      );
    }

    if (_optionLooksLikeMathExpression(value)) {
      return Math.tex(
        value,
        textStyle: effectiveTextStyle,
        mathStyle: MathStyle.text,
        onErrorFallback: (_) => Text(
          value,
          style: effectiveTextStyle,
          softWrap: true,
          textWidthBasis: TextWidthBasis.longestLine,
        ),
      );
    }

    return Text(
      value,
      style: effectiveTextStyle,
      softWrap: true,
      textWidthBasis: TextWidthBasis.longestLine,
    );
  }

  Widget _buildInlineOptionText({
    required String value,
    required TextStyle textStyle,
  }) {
    final pattern = RegExp(r'\$([^$]+)\$');
    final spans = <InlineSpan>[];
    var current = 0;

    for (final match in pattern.allMatches(value)) {
      if (match.start > current) {
        spans.add(
          TextSpan(
            text: value.substring(current, match.start),
            style: textStyle,
          ),
        );
      }

      final tex = match.group(1);
      if (tex == null || tex.isEmpty) {
        spans.add(TextSpan(text: match.group(0), style: textStyle));
      } else {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            baseline: TextBaseline.alphabetic,
            child: Math.tex(
              tex,
              mathStyle: MathStyle.text,
              textStyle: textStyle.copyWith(
                fontSize: (textStyle.fontSize ?? 18) * 1.05,
              ),
              onErrorFallback: (_) => Text('\$$tex\$', style: textStyle),
            ),
          ),
        );
      }

      current = match.end;
    }

    if (current < value.length) {
      spans.add(TextSpan(text: value.substring(current), style: textStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      softWrap: true,
      textWidthBasis: TextWidthBasis.longestLine,
    );
  }

  String _normalizeInlineMathDelimiters(String value) {
    return value.replaceAll(r'\$', r'$');
  }

  bool _hasInlineMathSegments(String value) {
    return RegExp(r'\$[^$]+\$').hasMatch(value);
  }

  bool _optionLooksLikeMathExpression(String value) {
    if (value.isEmpty) return false;

    final hasStrongTex =
        value.contains(r'$$') ||
        value.contains(r'\(') ||
        value.contains(r'\[') ||
        value.contains('{') ||
        value.contains('}') ||
        RegExp(r'\\[a-zA-Z]+').hasMatch(value);
    if (hasStrongTex) return true;

    // If there are normal words (e.g. "ili", "or"), render as plain text.
    if (RegExp(r'\b[a-zA-Z]{2,}\b').hasMatch(value)) {
      return false;
    }

    return RegExp(r'[+\-*/=^|_]').hasMatch(value);
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
    final overlay = _rootOverlayOrNull();
    if (overlay == null) return;
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
    overlay.insert(_xpOverlay!);
    Future.delayed(const Duration(milliseconds: 900), () {
      _xpOverlay?.remove();
      _xpOverlay = null;
    });
  }

  void _showStreakFlame(int streak) {
    if (_reduceMotion) return;
    final overlay = _rootOverlayOrNull();
    if (overlay == null) return;
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
    overlay.insert(_streakOverlay!);
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
      _showMasteryBurst(label: t.masteryMax, color: theme.colorScheme.primary);
    }
  }

  void _showMasteryBurst({required String label, required Color color}) {
    final overlay = _rootOverlayOrNull();
    if (overlay == null) return;
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
    overlay.insert(_masteryOverlay!);
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

  Future<void> _showHintModal() async {
    final t = context.t;
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    final stepByStepFormula = _resolveStepByStepFormula();
    final lightHint = widget.question.hintLight?.trim();
    final mediumHint = widget.question.hintMedium?.trim();
    final fullHint = widget.question.hintFull?.trim();
    final correctOptionText = _resolveCorrectOptionText();
    final resolvedLightHint = _firstNonEmptyText([
      lightHint,
      _buildFallbackLightHint(correctOptionText),
    ]);
    final resolvedMediumHint = _firstNonEmptyText([
      mediumHint,
      _buildFallbackMediumHint(correctOptionText),
    ]);
    final resolvedFullHint = _firstNonEmptyText([
      fullHint,
      _buildFallbackFullHint(correctOptionText),
    ]);
    final stepItems = widget.question.steps.isNotEmpty
        ? widget.question.steps
        : quizProvider.currentSteps;
    final hasStepExplanations = stepItems.isNotEmpty;

    final selectedHint = await showModalBottomSheet<_HintSelection>(
      context: context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.auto_awesome, color: Colors.deepPurple),
            title: Text(t.formulaHintTitle),
            subtitle: stepByStepFormula == null
                ? Text(t.noHintAvailable)
                : null,
            onTap: stepByStepFormula != null
                ? () {
                    quizProvider.markHintUsedForCurrentQuestion();
                    progress.penalizeXp(5);
                    Navigator.pop(
                      sheetContext,
                      _HintSelection(
                        title: t.formulaHintTitle,
                        text: stepByStepFormula,
                        isStepByStep: true,
                      ),
                    );
                  }
                : null,
          ),
          ListTile(
            leading: Icon(Icons.lightbulb_outline, color: Colors.blue),
            title: Text(t.smallHint),
            subtitle: resolvedLightHint == null
                ? Text(t.noHintAvailable)
                : null,
            onTap: resolvedLightHint != null
                ? () {
                    quizProvider.markHintUsedForCurrentQuestion();
                    progress.penalizeXp(1);
                    Navigator.pop(
                      sheetContext,
                      _HintSelection(
                        title: t.smallHint,
                        text: resolvedLightHint,
                      ),
                    );
                  }
                : null,
          ),
          ListTile(
            leading: Icon(Icons.lightbulb, color: Colors.orange),
            title: Text(t.mediumHint),
            subtitle: resolvedMediumHint == null
                ? Text(t.noHintAvailable)
                : null,
            onTap: resolvedMediumHint != null
                ? () {
                    quizProvider.markHintUsedForCurrentQuestion();
                    progress.penalizeXp(3);
                    Navigator.pop(
                      sheetContext,
                      _HintSelection(
                        title: t.mediumHint,
                        text: resolvedMediumHint,
                      ),
                    );
                  }
                : null,
          ),
          ListTile(
            leading: Icon(Icons.lightbulb, color: Colors.red),
            title: Text(t.fullHint),
            subtitle: !hasStepExplanations && resolvedFullHint == null
                ? Text(t.noHintAvailable)
                : null,
            onTap: hasStepExplanations || resolvedFullHint != null
                ? () {
                    quizProvider.markHintUsedForCurrentQuestion();
                    progress.penalizeXp(5);
                    if (hasStepExplanations) {
                      Navigator.pop(sheetContext);
                      FormulaHintBottomSheet.showSteps(context, stepItems);
                    } else if (resolvedFullHint != null) {
                      Navigator.pop(
                        sheetContext,
                        _HintSelection(
                          title: t.fullHint,
                          text: resolvedFullHint,
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
    );

    if (!mounted || selectedHint == null || selectedHint.text.isEmpty) return;

    if (selectedHint.isStepByStep) {
      await FormulaHintBottomSheet.show(context, selectedHint.text);
      return;
    }

    await _showHintTextDialog(
      title: selectedHint.title,
      text: selectedHint.text,
    );
  }

  String? _resolveStepByStepFormula() {
    final candidates = [
      widget.question.explanation,
      widget.question.hintFull,
      widget.question.hintMedium,
      widget.question.hintLight,
    ];
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  String? _firstNonEmptyText(List<String?> candidates) {
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final value = candidate.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  String? _resolveSelectedOptionText() {
    for (final option in widget.options) {
      if (option.id != selectedAnswer) continue;
      final value = option.text.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  MistakeType _resolveMistakeTypeForFeedback() {
    return StepExplanationController.detectMistakeType(
      studentAnswer: _resolveSelectedOptionText(),
      expectedAnswer: _resolveCorrectOptionText(),
      expression: widget.question.text,
    );
  }

  String _resolveMistakeExplanation() {
    final explicit = _firstNonEmptyText([
      widget.question.explanation,
      widget.question.hintFull,
      widget.question.hintMedium,
    ]);
    if (explicit != null) return explicit;

    switch (_resolveMistakeTypeForFeedback()) {
      case MistakeType.signError:
        return 'Pazi na znakove dok prebacujes clanove sa jedne strane jednakosti na drugu.';
      case MistakeType.denominatorError:
        return 'Kada radis sa razlomcima, proveri da li si pravilno tretirao imenilac u svakom koraku.';
      case MistakeType.orderOfOperations:
        return 'Primeni redosled operacija: prvo zagrade, zatim mnozenje/deljenje, pa sabiranje/oduzimanje.';
      case MistakeType.unknown:
        return 'Hajde da prodjemo resenje korak po korak i pronadjemo gde je doslo do greske.';
    }
  }

  String? _resolveCommonMisconception() {
    switch (_resolveMistakeTypeForFeedback()) {
      case MistakeType.signError:
        return 'Menjanje strane jednakosti menja i znak.';
      case MistakeType.denominatorError:
        return 'Brojilac i imenilac moraju da se tretiraju konzistentno.';
      case MistakeType.orderOfOperations:
        return 'Operacije se ne izvrsavaju sleva nadesno bez prioriteta.';
      case MistakeType.unknown:
        return null;
    }
  }

  String? _resolveCorrectOptionText() {
    for (final option in widget.options) {
      if (!option.isCorrect) continue;
      final value = option.text.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  String? _buildFallbackLightHint(String? correctOptionText) {
    if (correctOptionText == null || correctOptionText.isEmpty) return null;
    final firstChar = correctOptionText.trim()[0];
    return 'Tacan odgovor pocinje slovom/simbolom "$firstChar".';
  }

  String? _buildFallbackMediumHint(String? correctOptionText) {
    if (correctOptionText == null || correctOptionText.isEmpty) return null;
    final length = correctOptionText.trim().length;
    return 'Tacan odgovor ima oko $length karaktera.';
  }

  String? _buildFallbackFullHint(String? correctOptionText) {
    if (correctOptionText == null || correctOptionText.isEmpty) return null;
    return 'Tacan odgovor je: $correctOptionText';
  }

  Future<void> _showHintTextDialog({
    required String title,
    required String text,
  }) async {
    final t = context.t;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: MathContentText(
          value: text,
          style: Theme.of(dialogContext).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.gotIt),
          ),
        ],
      ),
    );
  }
}

class _HintSelection {
  final String title;
  final String text;
  final bool isStepByStep;

  const _HintSelection({
    required this.title,
    required this.text,
    this.isStepByStep = false,
  });
}

class OptionItem {
  final String id;
  final String text;
  final bool isCorrect;

  OptionItem({required this.id, required this.text, required this.isCorrect});
}
