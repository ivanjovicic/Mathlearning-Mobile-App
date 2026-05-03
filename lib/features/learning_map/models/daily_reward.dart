enum DailyRewardType { xp, cosmetic, streakBoost }

class DailyReward {
  const DailyReward({
    required this.type,
    required this.title,
    required this.subtitle,
    this.xpAmount,
    this.streakBoosts,
    this.cosmeticName,
  });

  final DailyRewardType type;
  final String title;
  final String subtitle;
  final int? xpAmount;
  final int? streakBoosts;
  final String? cosmeticName;
}