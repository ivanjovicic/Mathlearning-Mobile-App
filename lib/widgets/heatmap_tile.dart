import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/heatmap_provider.dart';

class HeatmapTile extends StatefulWidget {
  final int value;
  final int max;
  final int delay; // ms

  const HeatmapTile({
    super.key,
    required this.value,
    required this.max,
    required this.delay,
  });

  @override
  State<HeatmapTile> createState() => _HeatmapTileState();
}

class _HeatmapTileState extends State<HeatmapTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scale = Tween<double>(begin: 0.6, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final heatmapProvider = Provider.of<HeatmapProvider>(context, listen: false);
    
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: heatmapProvider.getIntensityColor(widget.value, widget.max),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
