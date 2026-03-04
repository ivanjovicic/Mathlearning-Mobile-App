import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_i18n.dart';
import '../../state/onboarding_provider.dart';
import '../../state/settings_provider.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const int _totalSteps = 4;
  bool _showConfetti = false;

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _finish() async {
    final ob = Provider.of<OnboardingProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    // Persist daily review preference
    if (ob.dailyReview) {
      await settings.setDailyReminderEnabled(true);
    }

    // Show confetti, then navigate
    setState(() => _showConfetti = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    await ob.completeOnboarding();

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final ob = Provider.of<OnboardingProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final t = context.t;

    final pages = [
      // ── 1. Welcome ──
      OnboardingPage(
        title: t.obWelcomeTitle,
        subtitle: t.obWelcomeSubtitle,
        icon: Icons.school_rounded,
        currentStep: 0,
        totalSteps: _totalSteps,
        nextLabel: t.obContinue,
        content: const SizedBox.shrink(),
        onNext: _next,
      ),

      // ── 2. Choose Language ──
      OnboardingPage(
        title: t.obLanguageTitle,
        subtitle: t.obLanguageSubtitle,
        icon: Icons.language_rounded,
        currentStep: 1,
        totalSteps: _totalSteps,
        showBack: true,
        onBack: _back,
        nextLabel: t.obContinue,
        content: _LanguagePicker(
          selected: settings.language,
          onChanged: (lang) => settings.setLanguage(lang),
        ),
        onNext: _next,
      ),

      // ── 3. Difficulty ──
      OnboardingPage(
        title: t.obDifficultyTitle,
        subtitle: t.obDifficultySubtitle,
        icon: Icons.speed_rounded,
        currentStep: 2,
        totalSteps: _totalSteps,
        showBack: true,
        onBack: _back,
        nextLabel: t.obContinue,
        content: _DifficultyPicker(
          selected: ob.difficulty,
          onChanged: ob.setDifficulty,
          easyLabel: t.obEasy,
          normalLabel: t.obNormal,
          hardLabel: t.obHard,
        ),
        onNext: _next,
      ),

      // ── 4. Daily Review + Finish ──
      OnboardingPage(
        title: t.obDailyTitle,
        subtitle: t.obDailySubtitle,
        icon: Icons.notifications_active_rounded,
        currentStep: 3,
        totalSteps: _totalSteps,
        showBack: true,
        onBack: _back,
        nextLabel: t.obStartLearning,
        content: _DailyReviewToggle(
          value: ob.dailyReview,
          label: t.obEnableReminder,
          onChanged: ob.setDailyReview,
        ),
        onNext: _finish,
      ),
    ];

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(key: ValueKey(_step), child: pages[_step]),
        ),

        // ── Confetti overlay ──
        if (_showConfetti) const _ConfettiOverlay(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Language picker — grid of language chips
// ═══════════════════════════════════════════════════════════════════════
class _LanguagePicker extends StatelessWidget {
  final AppLanguage selected;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguagePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: AppLanguage.values.map((lang) {
        final isSelected = lang == selected;
        return ChoiceChip(
          label: Text(
            lang.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? cs.onPrimary : cs.onSurface,
            ),
          ),
          selected: isSelected,
          selectedColor: cs.primary,
          backgroundColor: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          onSelected: (_) => onChanged(lang),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Difficulty picker — three stacked buttons
// ═══════════════════════════════════════════════════════════════════════
class _DifficultyPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final String easyLabel;
  final String normalLabel;
  final String hardLabel;

  const _DifficultyPicker({
    required this.selected,
    required this.onChanged,
    required this.easyLabel,
    required this.normalLabel,
    required this.hardLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _difficultyTile(context, easyLabel, '🌱'),
        _difficultyTile(context, normalLabel, '⚡'),
        _difficultyTile(context, hardLabel, '🔥'),
      ],
    );
  }

  Widget _difficultyTile(BuildContext context, String label, String emoji) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = selected == label;

    return GestureDetector(
      onTap: () => onChanged(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? cs.onPrimary : cs.onSurface,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: cs.onPrimary, size: 24),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Daily review toggle
// ═══════════════════════════════════════════════════════════════════════
class _DailyReviewToggle extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _DailyReviewToggle({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        activeColor: cs.primary,
        title: Text(
          label,
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '18:00',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Confetti overlay — celebratory burst on finish
// ═══════════════════════════════════════════════════════════════════════
class _ConfettiOverlay extends StatelessWidget {
  const _ConfettiOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rng = Random(42);

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(40, (i) {
            final startX = rng.nextDouble() * size.width;
            final endY = size.height * (0.3 + rng.nextDouble() * 0.7);
            final color = [
              Colors.amber,
              Colors.redAccent,
              Colors.greenAccent,
              Colors.blueAccent,
              Colors.purpleAccent,
              Colors.orangeAccent,
            ][i % 6];

            return Positioned(
              left: startX,
              top: -20,
              child:
                  Container(
                        width: 8 + rng.nextDouble() * 6,
                        height: 8 + rng.nextDouble() * 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )
                      .animate()
                      .moveY(
                        begin: 0,
                        end: endY,
                        duration: Duration(
                          milliseconds: 800 + rng.nextInt(600),
                        ),
                        curve: Curves.easeIn,
                      )
                      .fadeIn(duration: 100.ms)
                      .rotate(
                        begin: 0,
                        end: rng.nextDouble() * 2,
                        duration: 1200.ms,
                      )
                      .fadeOut(delay: 800.ms, duration: 400.ms),
            );
          }),
        ),
      ),
    );
  }
}
