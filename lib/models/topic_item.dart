import 'package:flutter/material.dart';

class TopicItem {
  final int id;
  final String name;
  final double accuracy;
  final bool locked;
  final IconData icon;
  final Color color;

  TopicItem({
    required this.id,
    required this.name,
    required this.accuracy,
    required this.locked,
    required this.icon,
    required this.color,
  });
}
