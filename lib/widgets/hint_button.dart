import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/coin_provider.dart';
import '../state/settings_provider.dart';

class HintButton extends StatefulWidget {
  final String hintType;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const HintButton({
    super.key,
    required this.hintType,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends State<HintButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Consumer2<CoinProvider, SettingsProvider>(
      builder: (context, coinProvider, settings, child) {
        final canAfford = coinProvider.canAffordHint(widget.hintType);
        final hintEnabled = settings.isHintTypeEnabled(widget.hintType);
        final canUseHint = canAfford && hintEnabled;
        final costText = !settings.hintsEnabled
            ? 'Iskljuceno'
            : hintEnabled
            ? coinProvider.getHintCostText(widget.hintType)
            : 'Onemoguceno';

        final bgColor = canUseHint
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest;
        final fgColor = canUseHint
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurface;

        final content = AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: reduceMotion ? 1.0 : _scaleAnimation.value,
              child: Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(25),
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTapDown: reduceMotion
                      ? null
                      : (canUseHint ? _onTapDown : null),
                  onTapUp: reduceMotion
                      ? null
                      : (canUseHint ? _onTapUp : null),
                  onTapCancel: reduceMotion ? null : _onTapCancel,
                  onTap:
                      canUseHint && !widget.isLoading ? widget.onPressed : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: canUseHint
                          ? [
                              BoxShadow(
                                color: colorScheme.secondary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : const [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading) ...[
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: fgColor,
                            ),
                          ),
                        ] else ...[
                          Icon(widget.icon, size: 18, color: fgColor),
                        ],
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: fgColor,
                              ),
                            ),
                            Text(
                              costText,
                              style: TextStyle(
                                fontSize: 12,
                                color: fgColor.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
        return content;
      },
    );
  }
}
