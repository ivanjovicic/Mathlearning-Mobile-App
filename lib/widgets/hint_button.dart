import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/coin_provider.dart';

class HintButton extends StatefulWidget {
  final String hintType;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const HintButton({
    Key? key,
    required this.hintType,
    required this.icon,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

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

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoinProvider>(
      builder: (context, coinProvider, child) {
        final canAfford = coinProvider.canAffordHint(widget.hintType);
        final costText = coinProvider.getHintCostText(widget.hintType);

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTapDown: canAfford ? _onTapDown : null,
                onTapUp: canAfford ? _onTapUp : null,
                onTapCancel: _onTapCancel,
                onTap: canAfford && !widget.isLoading ? widget.onPressed : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? Colors.yellow.shade400
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: canAfford
                        ? [
                            BoxShadow(
                              color: Colors.yellow.shade200,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isLoading) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          widget.icon,
                          size: 18,
                          color: canAfford
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ],
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: canAfford
                                  ? Colors.black
                                  : Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            costText,
                            style: TextStyle(
                              fontSize: 10,
                              color: canAfford
                                  ? Colors.black54
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
