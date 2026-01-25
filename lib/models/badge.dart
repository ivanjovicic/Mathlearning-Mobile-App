class AppBadge {
  final String name;
  final String icon;
  final bool unlocked;
  final double progress; // 0.0 - 1.0

  AppBadge({
    required this.name,
    required this.icon,
    required this.unlocked,
    required this.progress,
  });
}
