import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HeatmapProvider extends ChangeNotifier {
  final api = ApiService();
  String? token;

  List<int> weekData = List.filled(7, 0); // Mon → Sun

  Future<void> loadWeek() async {
    final data = await api.get("/api/progress/week-activity", token);
    if (data == null) return;

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
