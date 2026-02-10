import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/heatmap_provider.dart';
import '../state/progress_provider.dart';
import '../theme/astrax_theme.dart';

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
    final progress = Provider.of<ProgressProvider>(context);
    final now = DateTime.now();
    final days = List.generate(90, (i) => now.subtract(Duration(days: i)));

    return Scaffold(
      backgroundColor: AstraXTheme.bg,
      appBar: AppBar(
        title: const Text('Streak Heatmap'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final level = _levelForDay(day, heatmap, progress);
                final color = _colorForLevel(level);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: color.withValues(alpha: 0.7),
                    boxShadow: level == 0
                        ? const []
                        : [
                            BoxShadow(
                              color: color.withValues(alpha: 0.55),
                              blurRadius: 12,
                              spreadRadius: 1.5,
                            ),
                          ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AstraXTheme.panelLight,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AstraXTheme.neonGreen,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AstraXTheme.neonGreen.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: Color(0xFFFFF0E1),
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Streak: ${progress.streak} days',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _levelForDay(
    DateTime day,
    HeatmapProvider heatmap,
    ProgressProvider progress,
  ) {
    final key = _keyFor(day);
    final mapped = progress.dailyProgress[key];
    if (mapped != null) {
      if (mapped <= 0) return 0;
      if (mapped == 1) return 1;
      if (mapped == 2) return 2;
      return 3;
    }

    final weekValue = heatmap.weekData[day.weekday - 1];
    if (weekValue <= 0) return 0;
    final max = heatmap.maxValue == 0 ? 1 : heatmap.maxValue;
    final ratio = weekValue / max;
    if (ratio < 0.34) return 1;
    if (ratio < 0.67) return 2;
    return 3;
  }

  String _keyFor(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  Color _colorForLevel(int level) {
    switch (level) {
      case 0:
        return const Color(0xFF2A2B45);
      case 1:
        return const Color(0xFF5CFFB8);
      case 2:
        return const Color(0xFF6DFCD5);
      case 3:
      default:
        return const Color(0xFF8CFFE5);
    }
  }
}
