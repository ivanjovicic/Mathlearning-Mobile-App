import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/heatmap_provider.dart';
import '../widgets/heatmap_tile.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HeatmapProvider>(context, listen: false).loadWeek();
    });
  }

  @override
  Widget build(BuildContext context) {
    final heatmap = Provider.of<HeatmapProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          "Nedeljna aktivnost",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildWeekLabels(),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final value = heatmap.weekData[i];
                final max = heatmap.maxValue;
                return HeatmapTile(value: value, max: max, delay: i * 120);
              }),
            ),
            const SizedBox(height: 20),
            Text(
              "Klikni na dan da vidis detalje.",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekLabels() {
    final colorScheme = Theme.of(context).colorScheme;
    const days = ["P", "U", "S", "C", "P", "S", "N"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (d) => Text(
              d,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          )
          .toList(),
    );
  }
}
