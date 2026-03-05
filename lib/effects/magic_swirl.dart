import 'dart:math';
import 'package:flutter/material.dart';

class MagicSwirl extends StatefulWidget {
  final Color color;
  final int rings;

  const MagicSwirl({super.key, required this.color, this.rings = 40});

  @override
  State<MagicSwirl> createState() => _MagicSwirlState();
}

class _MagicSwirlState extends State<MagicSwirl>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          return CustomPaint(
            painter: _SwirlPainter(
              color: widget.color,
              t: _controller.value,
              rings: widget.rings,
            ),
          );
        },
      ),
    );
  }
}

class _SwirlPainter extends CustomPainter {
  final Color color;
  final double t;
  final int rings;

  _SwirlPainter({required this.color, required this.t, required this.rings});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide / 1.2;

    for (int i = 0; i < rings; i++) {
      final progress = i / rings;

      final radius = maxR * progress;
      final angle = (t * 2 * pi) + progress * 4 * pi;

      // soften outer rings and make inner rings more visible
      paint.color = color.withAlpha((0.45 * (1 - progress) * 255).round());
      paint.strokeWidth = (1 - progress) * 2.2;

      final offset = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      canvas.drawCircle(offset, (1 - progress) * 6, paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
