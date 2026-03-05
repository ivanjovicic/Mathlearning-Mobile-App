import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HeatmapProvider extends ChangeNotifier {
  final api = ApiService();
  String? token;

  List<int> weekData = List.filled(7, 0); // Mon → Sun

  Future<void> loadWeek() async {
    final data = await api.get("/api/progress/week-activity", token);
    if (data == null) {
      // Backend fallback: derive minimal weekly signal from overview.
      final overview = await api.get("/api/progress/overview", token);
      if (overview == null) return;

      weekData = List.filled(7, 0);
      final rawDate = overview["lastActivityDay"] ?? overview["lastStreakDay"];
      final parsed = rawDate is String ? DateTime.tryParse(rawDate) : null;

      if (parsed != null) {
        final now = DateTime.now();
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));

        final index = DateTime(parsed.year, parsed.month, parsed.day)
            .difference(start)
            .inDays;
        if (index >= 0 && index < 7) {
          weekData[index] = 1;
        }
      }

      notifyListeners();
      return;
    }

    Map days = data["days"];

    // Pretvori u 7 vrednosti
    weekData = [];
    DateTime now = DateTime.now();
    DateTime start = now.subtract(Duration(days: now.weekday - 1)); // Monday

    for (int i = 0; i < 7; i++) {
      DateTime day = start.add(Duration(days: i));
      String key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
      weekData.add(days[key] ?? 0);
    }

    notifyListeners();
  }

  int get maxValue => weekData.isEmpty ? 1 : weekData.reduce((a, b) => a > b ? a : b);

  Color getIntensityColor(int value, int max) {
    if (value == 0) return Colors.white.withValues(alpha: 0.08);

    double ratio = value / max;

    if (ratio < 0.25) return Colors.green.shade200;
    if (ratio < 0.50) return Colors.green.shade400;
    if (ratio < 0.75) return Colors.green.shade600;

    return Colors.green.shade800;
  }
}
