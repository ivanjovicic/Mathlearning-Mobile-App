import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/heatmap_provider.dart';
import '../state/progress_provider.dart';
import '../widgets/ui/app_section.dart';
import '../widgets/ui/state_scaffold.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHeatmap();
  }

  Future<void> _loadHeatmap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Provider.of<HeatmapProvider>(context, listen: false).loadWeek();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final heatmap = Provider.of<HeatmapProvider>(context);
    final progress = Provider.of<ProgressProvider>(context);
    final now = DateTime.now();
    final days = List.generate(90, (i) => now.subtract(Duration(days: i)));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Streak Heatmap'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: StateScaffold(
          isLoading: _loading,
          isEmpty: false,
          error: _error,
          onRetry: _loadHeatmap,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: AppSection(
                  title: 'Poslednjih 90 dana',
                  padding: EdgeInsets.zero,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Streak: ${progress.streak} days',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
              ),
            ],
          ),
        ),
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
