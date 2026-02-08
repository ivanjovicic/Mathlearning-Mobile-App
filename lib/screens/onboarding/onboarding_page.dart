import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A single page within the onboarding flow.
///
/// Uses the app's current theme (not hardcoded colours) so it works
/// with every visual theme (Fantasy, Retro, Sci-Fi, …).
class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget content;
  final VoidCallback onNext;
  final String nextLabel;
  final bool showBack;
  final VoidCallback? onBack;
  final int currentStep;
  final int totalSteps;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.content,
    required this.onNext,
    required this.currentStep,
    required this.totalSteps,
    this.nextLabel = 'Continue',
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // ── Top bar: back button + step dots ──
              const SizedBox(height: 12),
              Row(
                children: [
                  if (showBack)
                    IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  _StepDots(
                    current: currentStep,
                    total: totalSteps,
                    activeColor: cs.primary,
                    inactiveColor: cs.onSurface.withValues(alpha: 0.25),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const Spacer(flex: 2),

              // ── Icon ──
              _buildAnimated(
                reduceMotion: reduceMotion,
                delay: Duration.zero,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primaryContainer,
                  ),
                  child: Icon(icon, size: 64, color: cs.onPrimaryContainer),
                ),
              ),

              const SizedBox(height: 32),

              // ── Title ──
              _buildAnimated(
                reduceMotion: reduceMotion,
                delay: 100.ms,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Subtitle ──
              _buildAnimated(
                reduceMotion: reduceMotion,
                delay: 180.ms,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Dynamic content ──
              _buildAnimated(
                reduceMotion: reduceMotion,
                delay: 260.ms,
                child: content,
              ),

              const Spacer(flex: 3),

              // ── Continue button ──
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    nextLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimated({
    required bool reduceMotion,
    required Duration delay,
    required Widget child,
  }) {
    if (reduceMotion) return child;
    return child
        .animate()
        .fadeIn(duration: 400.ms, delay: delay)
        .moveY(begin: 18, end: 0, duration: 400.ms, delay: delay);
  }
}

// ── Step indicator dots ──────────────────────────────────────────────
class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  final Color activeColor;
  final Color inactiveColor;

  const _StepDots({
    required this.current,
    required this.total,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i <= current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}
