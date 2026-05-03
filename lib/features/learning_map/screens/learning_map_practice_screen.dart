import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/models/adaptive_learning_path.dart';
import 'package:mathlearning/features/learning_map/models/practice_launch_plan.dart';
import 'package:mathlearning/features/learning_map/models/practice_question.dart';
import 'package:mathlearning/features/learning_map/providers/learning_map_provider.dart';
import 'package:mathlearning/features/learning_map/services/practice_repository.dart';
import 'package:provider/provider.dart';

enum _PracticeStage { intro, loading, playing, celebration, summary }

class LearningMapPracticeScreen extends StatefulWidget {
  const LearningMapPracticeScreen({
    super.key,
    required this.plan,
    this.repository,
  });

  final PracticeLaunchPlan plan;
  final PracticeRepository? repository;

  @override
  State<LearningMapPracticeScreen> createState() =>
      _LearningMapPracticeScreenState();
}

class _LearningMapPracticeScreenState extends State<LearningMapPracticeScreen>
    with SingleTickerProviderStateMixin {
  late final PracticeRepository _repository;
  late final AnimationController _shakeController;

  _PracticeStage _stage = _PracticeStage.intro;
  List<PracticeQuestion> _questions = const [];
  int _index = 0;
  int _correctCount = 0;
  int? _selectedOptionId;
  bool _isProcessingAnswer = false;

  // Pre-computed at session end so celebration and summary share the same values.
  int _xpEarned = 0;
  double _masteryDelta = 0.0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiPracticeRepository();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Run')),
      body: switch (_stage) {
        _PracticeStage.intro => _buildIntro(),
        _PracticeStage.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        _PracticeStage.playing => _buildQuestionStage(),
        _PracticeStage.celebration => _buildCelebration(),
        _PracticeStage.summary => _buildSummary(),
      },
    );
  }

  Widget _buildIntro() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.plan.skillTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _DifficultyDots(difficulty: widget.plan.difficulty),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text('Clear 10 quick gates to power up this skill!'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _startPractice,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Let\'s go! →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionStage() {
    final question = _questions[_index];
    final progress = (_index + 1) / _questions.length;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gate ${_index + 1}/${_questions.length}',
              style: theme.textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final dx = math.sin(_shakeController.value * math.pi * 5) * 8;
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  question.prompt,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ...question.options.map(_buildAnswerOption),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(PracticeOption option) {
    final question = _questions[_index];
    final isSelected = _selectedOptionId == option.id;
    final isCorrect = question.isCorrect(option.id);

    Color? background;
    if (isSelected && _isProcessingAnswer) {
      background = isCorrect
          ? Colors.green.withValues(alpha: 0.16)
          : Colors.red.withValues(alpha: 0.16);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: Semantics(
          button: true,
          label: option.label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: OutlinedButton(
              onPressed: _isProcessingAnswer
                  ? null
                  : () => _submitOption(option.id),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    final total = _questions.length;
    final accuracy = total == 0 ? 0.0 : _correctCount / total;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final String emoji;
    final String praise;
    if (accuracy >= 0.9) {
      emoji = '🔥';
      praise = 'You\'re on fire! 🔥';
    } else if (accuracy >= 0.7) {
      emoji = '⭐';
      praise = 'Great job! ⭐';
    } else {
      emoji = '💪';
      praise = 'Keep it up — you\'ll nail it next time! 💪';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(emoji, style: const TextStyle(fontSize: 72))
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1.0, 1.0),
                    duration: 480.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(duration: 200.ms),
              const SizedBox(height: 20),
              Text(
                    praise,
                    style: tt.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: cs.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate(delay: 160.ms)
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.15, duration: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 32),
              _CelebrationStat(
                label: '+$_xpEarned XP earned!',
                color: cs.primary,
                delay: 280.ms,
              ),
              const SizedBox(height: 12),
              _CelebrationStat(
                label: '$_correctCount/${_questions.length} nailed it ✅',
                color: cs.secondary,
                delay: 380.ms,
              ),
              const SizedBox(height: 12),
              _CelebrationStat(
                label: 'Skill +${(_masteryDelta * 100).round()}% stronger!',
                color: cs.tertiary,
                delay: 480.ms,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child:
                    FilledButton(
                          onPressed: () =>
                              setState(() => _stage = _PracticeStage.summary),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Keep going! →',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        )
                        .animate(delay: 560.ms)
                        .fadeIn(duration: 260.ms)
                        .slideY(
                          begin: 0.2,
                          duration: 260.ms,
                          curve: Curves.easeOut,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final total = _questions.length;
    final accuracy = total == 0 ? 0.0 : _correctCount / total;
    final provider = context.read<LearningMapProvider>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Icon(
            accuracy >= 0.7 ? Icons.emoji_events : Icons.auto_awesome,
            size: 56,
            color: accuracy >= 0.7 ? Colors.amber : Colors.blue,
          ),
          const SizedBox(height: 12),
          Text(
            accuracy >= 0.7
                ? 'You crushed it! 🎉'
                : 'Good fight — keep training! 💪',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          _SummaryTile(
            title: 'Gates cleared',
            value: '$_correctCount / $total',
          ),
          const SizedBox(height: 10),
          _SummaryTile(title: 'XP earned', value: '+$_xpEarned XP'),
          const SizedBox(height: 10),
          _SummaryTile(
            title: 'Skill power boost',
            value: '+${(_masteryDelta * 100).round()}%',
          ),
          const Spacer(),
          FilledButton(
            onPressed: () async {
              await provider.completePractice(
                plan: widget.plan,
                xpEarned: _xpEarned,
                masteryDelta: _masteryDelta,
                accuracy: accuracy,
              );
              if (widget.plan.userId.isNotEmpty) {
                await provider.refresh(widget.plan.userId);
              }
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Back to my map'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPractice() async {
    setState(() => _stage = _PracticeStage.loading);
    final questions = await _repository.loadQuestions(widget.plan, count: 10);
    if (!mounted) return;
    setState(() {
      _questions = questions;
      _index = 0;
      _correctCount = 0;
      _selectedOptionId = null;
      _isProcessingAnswer = false;
      _stage = _questions.isEmpty
          ? _PracticeStage.summary
          : _PracticeStage.playing;
    });
  }

  Future<void> _submitOption(int optionId) async {
    final question = _questions[_index];
    final isCorrect = question.isCorrect(optionId);

    setState(() {
      _selectedOptionId = optionId;
      _isProcessingAnswer = true;
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
      _correctCount += 1;
    } else {
      HapticFeedback.selectionClick();
      _shakeController
        ..reset()
        ..forward();
    }

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;

    final isLastQuestion = _index + 1 >= _questions.length;
    if (isLastQuestion) {
      HapticFeedback.heavyImpact();
      final total = _questions.length;
      final accuracy = total == 0 ? 0.0 : _correctCount / total;
      setState(() {
        _xpEarned = _calculateXp(total: total, correct: _correctCount);
        _masteryDelta = _calculateMasteryDelta(accuracy);
        _isProcessingAnswer = false;
        _selectedOptionId = null;
        _stage = _PracticeStage.celebration;
      });
      return;
    }

    setState(() {
      _index += 1;
      _selectedOptionId = null;
      _isProcessingAnswer = false;
    });
  }

  int _calculateXp({required int total, required int correct}) {
    final base = correct * 8;
    final bonus = switch (widget.plan.difficulty) {
      SkillDifficulty.easy => 8,
      SkillDifficulty.medium => 14,
      SkillDifficulty.hard => 20,
    };
    return base + bonus;
  }

  double _calculateMasteryDelta(double accuracy) {
    final raw = (accuracy * 0.14) - 0.03;
    return raw.clamp(0.02, 0.14);
  }
}

class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.difficulty});

  final SkillDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final dots = difficulty.dots;
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            index < dots ? Icons.circle : Icons.circle_outlined,
            size: 12,
            color: index < dots ? color : color.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CelebrationStat extends StatelessWidget {
  const _CelebrationStat({
    required this.label,
    required this.color,
    required this.delay,
  });

  final String label;
  final Color color;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        )
        .animate(delay: delay)
        .fadeIn(duration: 280.ms)
        .slideX(begin: -0.06, duration: 280.ms, curve: Curves.easeOut);
  }
}
