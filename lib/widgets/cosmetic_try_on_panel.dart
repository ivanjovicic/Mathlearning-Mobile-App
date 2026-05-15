import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/social_cosmetic_loadout.dart';
import '../models/user_avatar.dart';
import '../state/avatar_provider.dart';
import '../state/cosmetic_preview_provider.dart';
import 'avatar_widget.dart';
import 'cosmetic_visuals.dart';

class CosmeticTryOnPanel extends StatefulWidget {
  const CosmeticTryOnPanel({
    super.key,
    required this.item,
    required this.onBackToLook,
    this.onChaseThis,
    this.isCurrentTarget = false,
  });

  final SocialCosmeticFlexItem item;
  final VoidCallback onBackToLook;
  final Future<void> Function()? onChaseThis;
  final bool isCurrentTarget;

  @override
  State<CosmeticTryOnPanel> createState() => _CosmeticTryOnPanelState();
}

class _CosmeticTryOnPanelState extends State<CosmeticTryOnPanel>
    with TickerProviderStateMixin {
  late final AnimationController _morphController;
  late final AnimationController _loopController;
  CosmeticPreviewProvider? _preview;
  bool _previewStarted = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    )..forward();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _preview ??= _maybeRead<CosmeticPreviewProvider>(context);
    if (!_previewStarted) {
      _previewStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _preview?.startPreview(widget.item);
      });
    }
  }

  @override
  void dispose() {
    if (_preview?.isPreviewingItem(widget.item.itemId) == true) {
      _preview?.clearPreview();
    }
    _morphController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final avatar = context.watch<AvatarProvider>();
    final preview = _preview;
    final userId =
        avatar.avatarConfig?.userId ?? preview?.userId ?? 'local-preview';
    final baseAvatar = avatar.avatarConfig ?? UserAvatar.defaults(userId);
    final baseLoadout = SocialCosmeticLoadout.fromLocal(
      userId: userId,
      avatar: avatar.avatarConfig,
      inventory: avatar.inventory,
      catalog: avatar.catalog,
    );
    final previewAvatar =
        preview?.applyToAvatar(avatar.avatarConfig, fallbackUserId: userId) ??
        applyPreviewItemToAvatar(baseAvatar, widget.item);
    final previewLoadout =
        preview?.applyToLoadout(baseLoadout) ??
        applyPreviewItemToLoadout(baseLoadout, widget.item);
    final rarityColor = CosmeticVisuals.rarityColor(widget.item.rarity);
    final rarityGradient = CosmeticVisuals.rarityGradient(widget.item.rarity);

    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight * 0.34).clamp(170.0, 228.0).toDouble()
            : 228.0;
        final beforeSize = heroHeight < 200 ? 92.0 : 116.0;
        final afterSize = heroHeight < 200 ? 104.0 : 128.0;

        return SingleChildScrollView(
          key: const Key('cosmetic_try_on_panel'),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'See it on your avatar',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient:
                        rarityGradient ??
                        LinearGradient(
                          colors: [
                            rarityColor.withValues(alpha: 0.24),
                            rarityColor.withValues(alpha: 0.07),
                            colors.surfaceContainerHighest.withValues(
                              alpha: 0.92,
                            ),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                    border: Border.all(
                      color: rarityColor.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.18),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        key: const Key('previewing_pill'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: rarityColor.withValues(alpha: 0.40),
                          ),
                        ),
                        child: Text(
                          'Previewing',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: rarityColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.item.name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Preview equipped',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: heroHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _loopController,
                                builder: (context, child) {
                                  final pulse =
                                      math.sin(
                                            _loopController.value *
                                                math.pi *
                                                2,
                                          ) *
                                          0.5 +
                                      0.5;
                                  return DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          rarityColor.withValues(
                                            alpha: 0.10 + pulse * 0.12,
                                          ),
                                          rarityColor.withValues(
                                            alpha: 0.02 + pulse * 0.05,
                                          ),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (isPreviewEffectLike(widget.item))
                              Positioned.fill(
                                child: _EffectDemoLayer(
                                  item: widget.item,
                                  color: rarityColor,
                                  progress: _loopController,
                                ),
                              ),
                            AnimatedBuilder(
                              animation: _morphController,
                              builder: (context, child) {
                                final t = Curves.easeOutBack.transform(
                                  _morphController.value,
                                );
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 172 + t * 18,
                                      height: 172 + t * 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: rarityColor.withValues(
                                              alpha: 0.10 + t * 0.24,
                                            ),
                                            blurRadius: 20 + t * 18,
                                            spreadRadius: 1 + t * 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Opacity(
                                      opacity: 1 - t,
                                      child: Transform.scale(
                                        scale: 1 - t * 0.06,
                                        child: _AvatarLookPreview(
                                          config: baseAvatar,
                                          loadout: baseLoadout,
                                          accentColor: colors.outline,
                                          size: beforeSize,
                                        ),
                                      ),
                                    ),
                                    Opacity(
                                      opacity: 0.22 + t * 0.78,
                                      child: Transform.scale(
                                        scale: 0.90 + t * 0.10,
                                        child: _AvatarLookPreview(
                                          config: previewAvatar,
                                          loadout: previewLoadout,
                                          accentColor: rarityColor,
                                          size: afterSize,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _LookStateChip(
                            label: 'Your look',
                            config: baseAvatar,
                            loadout: baseLoadout,
                            accentColor: colors.outline,
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: colors.onSurfaceVariant,
                          ),
                          _LookStateChip(
                            label: 'Preview equipped',
                            config: previewAvatar,
                            loadout: previewLoadout,
                            accentColor: rarityColor,
                            highlighted: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('chase_this_button'),
                    onPressed:
                        widget.isCurrentTarget ||
                            _saving ||
                            widget.onChaseThis == null
                        ? null
                        : _handleChase,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.gps_fixed_rounded),
                    label: Text(
                      widget.isCurrentTarget ? 'Already chasing' : 'Chase this',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: rarityColor,
                      foregroundColor: colors.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('back_to_my_look_button'),
                    onPressed: _handleBackToLook,
                    icon: const Icon(Icons.undo_rounded),
                    label: const Text('Back to my look'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleChase() async {
    final action = widget.onChaseThis;
    if (action == null) return;
    setState(() => _saving = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _handleBackToLook() {
    _preview?.clearPreview();
    widget.onBackToLook();
  }

  T? _maybeRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }
}

class _AvatarLookPreview extends StatelessWidget {
  const _AvatarLookPreview({
    required this.config,
    required this.loadout,
    required this.accentColor,
    required this.size,
  });

  final UserAvatar config;
  final SocialCosmeticLoadout loadout;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final backgroundId = loadout.profileBackgroundId;
    Widget child = AvatarWidget(
      size: backgroundId == null ? size : size * 0.84,
      showFrame: true,
      overrideConfig: config,
      borderColor: accentColor,
    );

    if (backgroundId != null) {
      child = Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.08),
        decoration: CosmeticVisuals.backgroundDecoration(
          backgroundId,
          BorderRadius.circular(size * 0.22),
        ),
        child: Center(child: child),
      );
    }

    return child;
  }
}

class _LookStateChip extends StatelessWidget {
  const _LookStateChip({
    required this.label,
    required this.config,
    required this.loadout,
    required this.accentColor,
    this.highlighted = false,
  });

  final String label;
  final UserAvatar config;
  final SocialCosmeticLoadout loadout;
  final Color accentColor;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? accentColor.withValues(alpha: 0.14)
            : colors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarLookPreview(
            config: config,
            loadout: loadout,
            accentColor: accentColor,
            size: 42,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectDemoLayer extends StatelessWidget {
  const _EffectDemoLayer({
    required this.item,
    required this.color,
    required this.progress,
  });

  final SocialCosmeticFlexItem item;
  final Color color;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final isTrail = item.itemId.startsWith('trail_') ||
        item.slotLabel.toLowerCase() == 'trail';
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        return CustomPaint(
          painter: isTrail
              ? _TrailDemoPainter(color: color, t: progress.value)
              : _BurstDemoPainter(color: color, t: progress.value),
        );
      },
    );
  }
}

class _TrailDemoPainter extends CustomPainter {
  const _TrailDemoPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.14,
        size.width * 0.50,
        size.height * 0.46,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.88,
        size.width * 0.86,
        size.height * 0.32,
      );
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null) return;
    final guide = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, guide);

    for (var i = 5; i >= 1; i--) {
      final trailT = (t - i * 0.045).clamp(0.0, 1.0);
      final tangent = metric.getTangentForOffset(metric.length * trailT);
      if (tangent == null) continue;
      canvas.drawCircle(
        tangent.position,
        10 - i.toDouble(),
        Paint()
          ..color = color.withValues(alpha: 0.05 * i)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }

    final tangent = metric.getTangentForOffset(metric.length * t);
    if (tangent == null) return;
    canvas.drawCircle(
      tangent.position,
      17,
      Paint()
        ..color = color.withValues(alpha: 0.24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(tangent.position, 7, Paint()..color = color);
    canvas.drawCircle(
      tangent.position,
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_TrailDemoPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}

class _BurstDemoPainter extends CustomPainter {
  const _BurstDemoPainter({required this.color, required this.t});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = 30 + phase * 72;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = color.withValues(alpha: (1 - phase) * 0.28),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstDemoPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.color != color;
  }
}