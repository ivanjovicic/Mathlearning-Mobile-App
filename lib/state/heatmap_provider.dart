import 'package:flutter/material.dart';

import '../services/progress_api_service.dart';

class HeatmapProvider extends ChangeNotifier {
  final ProgressApiService api = ProgressApiService();
  Object? lastError;

  List<int> weekData = List<int>.filled(7, 0); // Mon -> Sun

  Future<void> loadWeek() async {
    final weekResult = await api.fetchWeekActivityResult();
    final data = weekResult.data;
    if (!weekResult.isSuccess || data == null) {
      lastError = weekResult.error;

      // Backend fallback: derive minimal weekly signal from overview.
      final overviewResult = await api.fetchOverviewResult();
      final overview = overviewResult.data;
      if (!overviewResult.isSuccess || overview == null) {
        lastError = overviewResult.error;
        return;
      }

      weekData = List<int>.filled(7, 0);
      final rawDate = overview['lastActivityDay'] ?? overview['lastStreakDay'];
      final parsed = rawDate is String ? DateTime.tryParse(rawDate) : null;

      if (parsed != null) {
        final now = DateTime.now();
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));

        final index = DateTime(
          parsed.year,
          parsed.month,
          parsed.day,
        ).difference(start).inDays;
        if (index >= 0 && index < 7) {
          weekData[index] = 1;
        }
      }

      notifyListeners();
      return;
    }

    lastError = null;
    final days = data['days'];
    if (days is! Map) {
      weekData = List<int>.filled(7, 0);
      notifyListeners();
      return;
    }

    // Convert to 7 values.
    weekData = <int>[];
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1)); // Monday

    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      weekData.add((days[key] as num?)?.toInt() ?? 0);
    }

    notifyListeners();
  }

  int get maxValue =>
      weekData.isEmpty ? 1 : weekData.reduce((a, b) => a > b ? a : b);

  Color getIntensityColor(int value, int max) {
    if (value == 0) return Colors.white.withValues(alpha: 0.08);

    final ratio = value / max;

    if (ratio < 0.25) return Colors.green.shade200;
    if (ratio < 0.50) return Colors.green.shade400;
    if (ratio < 0.75) return Colors.green.shade600;

    return Colors.green.shade800;
  }
}
