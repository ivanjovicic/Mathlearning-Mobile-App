import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:mathlearning/features/learning_map/widgets/cosmetic_equip_confirmation.dart';
import 'package:mathlearning/features/learning_map/widgets/cosmetic_fragment_card.dart';
import 'package:mathlearning/models/social_cosmetic_loadout.dart';
import 'package:mathlearning/services/cosmetics_service.dart';
import 'package:mathlearning/services/sound_service.dart';
import 'package:mathlearning/widgets/avatar_widget.dart';

// ---------------------------------------------------------------------------
// Confetti particle data (deterministic – no dart:math random at build time).
// ---------------------------------------------------------------------------
class _Particle {
  const _Particle({
    required this.x,
    required this.phase,
    required this.speedY,
    required this.drift,
    required this.color,
    required this.size,
    required this.rotSpeed,
    required this.isRect,
  });

  final double x; // base x [0..1]
  final double phase; // time offset [0..1]
  final double speedY; // fall speed multiplier
  final double drift; // horizontal sway amplitude [fraction of width]
  final Color color;
  final double size;
  final double rotSpeed;
  final bool isRect;
}

double _lcg(int seed, double lo, double hi) {
  final v = ((seed * 1664525 + 1013904223) & 0x7fffffff) / 0x7fffffff;
  return lo + v * (hi - lo);
}

List<_Particle> _buildParticles(Color accent) {
  final palette = [
    accent,
    accent.withValues(alpha: 0.65),
    Colors.white,
    Colors.white.withValues(alpha: 0.55),
    const Color(0xFFFFD700), // gold
    const Color(0xFFFF6B6B), // coral
    const Color(0xFF6BCEFF), // sky
  ];
  return List.generate(
    26,
    (i) => _Particle(
      x: _lcg(i * 7, 0.0, 1.0),
      phase: _lcg(i * 13, 0.0, 1.0),
      speedY: _lcg(i * 17, 0.35, 0.9),
      drift: _lcg(i * 23, 0.015, 0.065),
      color: palette[i % palette.length],
      size: _lcg(i * 31, 4.0, 11.0),
      rotSpeed: _lcg(i * 37, 0.5, 3.0),
      isRect: i % 3 != 0,
    ),
  );
}

// ---------------------------------------------------------------------------
// Confetti painter.
// ---------------------------------------------------------------------------
class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.particles, required this.t});

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (t + p.phase) % 1.0;
      final y = progress * size.height * (1 / p.speedY);
      final x =
          p.x * size.width +
          math.sin((t + p.phase) * 2 * math.pi * 2) * p.drift * size.width;
      final paint = Paint()..color = p.color;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * p.rotSpeed * math.pi * 2);

      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.45,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Large preview panel used inside the celebration (always animated).
// ---------------------------------------------------------------------------
class _CelebrationItemPreview extends StatefulWidget {
  const _CelebrationItemPreview({
    required this.rarity,
    required this.fragmentName,
  });

  final FragmentRarity rarity;
  final String fragmentName;

  @override
  State<_CelebrationItemPreview> createState() =>
      _CelebrationItemPreviewState();
}

class _CelebrationItemPreviewState extends State<_CelebrationItemPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CosmeticPreviewHero(
      key: ValueKey(widget.fragmentName),
      rarity: widget.rarity,
      fragmentName: widget.fragmentName,
      isCompleted: true,
      animate: true,
    );
  }
}

// ---------------------------------------------------------------------------
// Sparkle ring — 8 spark dots orbiting the preview.
// ---------------------------------------------------------------------------
class _SparkleRingPainter extends CustomPainter {
  const _SparkleRingPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.48;
    const count = 8;
    for (var i = 0; i < count; i++) {
      final angle = (i / count + t) * 2 * math.pi;
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final opacity = ((math.sin(angle * 2 + t * math.pi * 4) + 1) / 2).clamp(
        0.25,
        1.0,
      );
      canvas.drawCircle(
        pos,
        4.5,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_SparkleRingPainter old) => old.t != t;
}

class _UnlockBloomPainter extends CustomPainter {
  const _UnlockBloomPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.30);
    final radius = size.shortestSide * 0.72;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.30),
          color.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_UnlockBloomPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _AvatarAutoPreview extends StatelessWidget {
  const _AvatarAutoPreview({required this.itemName, required this.color});

  final String itemName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('unlock_avatar_auto_preview'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.36)),
      ),
      child: Row(
        children: [
          AvatarWidget(
            size: 48,
            showFrame: true,
            borderColor: color,
            overrideConfig: _loadoutFor(
              itemName,
            ).toAvatarConfig('unlock-preview'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avatar preview',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Try it on before you equip.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SocialCosmeticLoadout _loadoutFor(String name) {
    final itemId = CosmeticsService.instance.dailyRunItemIdForFragment(name);
    if (itemId.startsWith('frame_')) {
      return SocialCosmeticLoadout(avatarFrameId: itemId);
    }
    if (itemId.startsWith('effect_')) {
      if (itemId.contains('trail')) {
        return SocialCosmeticLoadout(trailId: itemId);
      }
      return SocialCosmeticLoadout(answerEffectId: itemId);
    }
    return SocialCosmeticLoadout(avatarGearId: itemId);
  }
}

class _VictoryHold extends StatelessWidget {
  const _VictoryHold({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('unlock_victory_hold'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            'Victory moment...',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CosmeticUnlockCelebration
//
// Shown via showDialog / showGeneralDialog when a cosmetic set is completed.
// ---------------------------------------------------------------------------
class CosmeticUnlockCelebration extends StatefulWidget {
  const CosmeticUnlockCelebration({
    super.key,
    required this.itemName,
    required this.rarity,
    this.onEquipNow,
    this.onViewCollection,
  });

  /// The cosmetic name without the " Fragment" suffix.
  final String itemName;
  final FragmentRarity rarity;

  /// Called when the user taps "Equip now". Dialog should be popped externally.
  final VoidCallback? onEquipNow;

  /// Called when the user taps "View collection". Dialog should be popped externally.
  final VoidCallback? onViewCollection;

  @override
  State<CosmeticUnlockCelebration> createState() =>
      _CosmeticUnlockCelebrationState();
}

class _CosmeticUnlockCelebrationState extends State<CosmeticUnlockCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _sparkleCtrl;
  late final AnimationController _entryCtrl;

  bool _equipping = false;
  bool _equipped = false;
  bool _ctaVisible = false;
  bool _holdStarted = false;
  bool _reduceMotion = false;
  Timer? _ctaTimer;

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..forward();

    // Sound: rare_fragment_reveal → reward_claim with a short gap.
    unawaited(SoundService.instance.playFinalGateUnlocked());
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) unawaited(SoundService.instance.playFinalGateWhoosh());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextReduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (nextReduce != _reduceMotion) {
      _reduceMotion = nextReduce;
      if (_reduceMotion) {
        _confettiCtrl.stop();
        _sparkleCtrl.stop();
        _entryCtrl.value = 1;
      } else {
        if (!_confettiCtrl.isAnimating) _confettiCtrl.repeat();
        if (!_sparkleCtrl.isAnimating) _sparkleCtrl.repeat();
      }
    }

    if (!_holdStarted) {
      _holdStarted = true;
      _ctaTimer = Timer(
        _reduceMotion ? Duration.zero : const Duration(milliseconds: 1050),
        () {
          if (!mounted) return;
          setState(() => _ctaVisible = true);
          unawaited(SoundService.instance.playRewardClaim());
        },
      );
    }
  }

  @override
  void dispose() {
    _ctaTimer?.cancel();
    _confettiCtrl.dispose();
    _sparkleCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEquip() async {
    if (_equipping || _equipped) return;
    setState(() => _equipping = true);
    widget.onEquipNow?.call();
    await CosmeticsService.instance.equipItem(widget.itemName);
    if (!mounted) return;
    setState(() {
      _equipping = false;
      _equipped = true;
    });
  }

  Color _rarityColor(ColorScheme scheme) => switch (widget.rarity) {
    FragmentRarity.common => scheme.secondary,
    FragmentRarity.rare => scheme.primary,
    FragmentRarity.epic => scheme.tertiary,
    FragmentRarity.legendary => const Color(0xFFFFB800),
  };

  String get _unlockHeadline {
    final upper = widget.itemName.toUpperCase();
    return '$upper UNLOCKED!';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rarityColor = _rarityColor(colors);
    final rarityLabel = switch (widget.rarity) {
      FragmentRarity.common => 'COMMON',
      FragmentRarity.rare => 'RARE',
      FragmentRarity.epic => 'EPIC',
      FragmentRarity.legendary => 'LEGENDARY',
    };

    // Rebuild particles with real colors once we have a ColorScheme.
    final particles = _buildParticles(rarityColor);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: AnimatedBuilder(
        animation: _entryCtrl,
        builder: (_, child) => Transform.scale(
          scale: Tween<double>(begin: 0.86, end: 1.0)
              .animate(
                CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack),
              )
              .value,
          child: Opacity(
            opacity: CurvedAnimation(
              parent: _entryCtrl,
              curve: Curves.easeOut,
            ).value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.45),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: const Key('unlock_rarity_bloom'),
                      painter: _UnlockBloomPainter(color: rarityColor),
                    ),
                  ),
                ),
                // ── Confetti layer ──────────────────────────────────────
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _confettiCtrl,
                      builder: (_, _) => CustomPaint(
                        painter: _ConfettiPainter(
                          particles: particles,
                          t: _confettiCtrl.value,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Content ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sparkle ring + preview.
                        SizedBox(
                          height: 148,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Sparkle orbit ring.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: AnimatedBuilder(
                                    animation: _sparkleCtrl,
                                    builder: (_, _) => CustomPaint(
                                      painter: _SparkleRingPainter(
                                        color: rarityColor,
                                        t: _sparkleCtrl.value,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Item preview.
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 110,
                                  child: _CelebrationItemPreview(
                                    rarity: widget.rarity,
                                    fragmentName: widget.itemName,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Rarity badge.
                        Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: rarityColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: rarityColor.withValues(alpha: 0.55),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                rarityLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(1.0, 1.0),
                              end: const Offset(1.06, 1.06),
                              duration: 900.ms,
                              curve: Curves.easeInOut,
                            ),

                        const SizedBox(height: 10),

                        // Big unlock headline.
                        Text(
                              _unlockHeadline,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: rarityColor,
                                height: 1.15,
                                shadows: [
                                  Shadow(
                                    color: rarityColor.withValues(alpha: 0.60),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 260.ms, delay: 180.ms)
                            .slideY(
                              begin: 0.12,
                              end: 0,
                              duration: 320.ms,
                              delay: 180.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 6),

                        // "5/5 collected" — all pips filled.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 5; i++) ...[
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: rarityColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: rarityColor.withValues(
                                        alpha: 0.55,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              if (i < 4) const SizedBox(width: 6),
                            ],
                            const SizedBox(width: 10),
                            Text(
                              '5/5 collected',
                              style: textTheme.labelSmall?.copyWith(
                                color: rarityColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ).animate(delay: 320.ms).fadeIn(duration: 240.ms),

                        const SizedBox(height: 14),

                        _AvatarAutoPreview(
                              itemName: widget.itemName,
                              color: rarityColor,
                            )
                            .animate(delay: 460.ms)
                            .fadeIn(duration: 260.ms)
                            .slideY(begin: 0.10, end: 0, duration: 280.ms),

                        const SizedBox(height: 18),

                        // CTAs — replaced by equip confirmation once equipped.
                        if (_equipped)
                          CosmeticEquipConfirmation(
                            itemName: widget.itemName,
                            itemType: cosmeticItemType(widget.itemName),
                            rarityColor: rarityColor,
                            onDone: null,
                          )
                        else if (!_ctaVisible)
                          _VictoryHold(color: rarityColor)
                        else ...[
                          if (widget.onEquipNow != null)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _equipping ? null : _handleEquip,
                                icon: _equipping
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.checkroom_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  _equipping ? 'Equipping…' : 'Equip now',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: rarityColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),

                          if (widget.onEquipNow != null &&
                              widget.onViewCollection != null)
                            const SizedBox(height: 8),

                          if (widget.onViewCollection != null)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: widget.onViewCollection,
                                icon: const Icon(
                                  Icons.collections_bookmark_rounded,
                                  size: 16,
                                ),
                                label: const Text('View collection'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: rarityColor,
                                  side: BorderSide(
                                    color: rarityColor.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
