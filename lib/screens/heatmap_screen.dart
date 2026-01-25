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
    Future.microtask(() {
      Provider.of<HeatmapProvider>(context, listen: false).loadWeek();
    });
  }

  @override
  Widget build(BuildContext context) {
    final heatmap = Provider.of<HeatmapProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Text(
          "📅 Nedeljna Aktivnost",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
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
                int value = heatmap.weekData[i];
                int max = heatmap.maxValue;

                return HeatmapTile(
                  value: value,
                  max: max,
                  delay: i * 120,
                );
              }),
            ),

            const SizedBox(height: 20),

            Text(
              "Klikni na dan da vidiš detalje.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWeekLabels() {
    final days = ["P", "U", "S", "Č", "P", "S", "N"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map((d) => Text(
                d,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ))
          .toList(),
    );
  }
}
