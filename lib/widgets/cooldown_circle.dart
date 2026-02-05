import 'package:flutter/material.dart';

class CooldownCircle extends StatefulWidget {
  final int seconds;
  final VoidCallback? onComplete;

  const CooldownCircle({super.key, required this.seconds, this.onComplete});

  @override
  State<CooldownCircle> createState() => _CooldownCircleState();
}

class _CooldownCircleState extends State<CooldownCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.seconds),
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final remaining = (widget.seconds * (1 - _controller.value)).ceil();

        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.secondaryContainer,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: _controller.value,
                strokeWidth: 6,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(colorScheme.secondary),
              ),
              Center(
                child: Text(
                  '$remaining',
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
