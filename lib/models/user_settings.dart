class UserSettings {
  final bool hintsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool dailyReminderEnabled;
  final int? dailyReminderHour;
  final int? dailyReminderMinute;

  const UserSettings({
    this.hintsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.dailyReminderEnabled = false,
    this.dailyReminderHour,
    this.dailyReminderMinute,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      hintsEnabled: json['hintsEnabled'] ?? json['hints_enabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? json['sound_enabled'] ?? true,
      vibrationEnabled:
          json['vibrationEnabled'] ?? json['vibration_enabled'] ?? true,
      dailyReminderEnabled:
          json['dailyReminderEnabled'] ??
          json['daily_reminder_enabled'] ??
          false,
      dailyReminderHour:
          json['dailyReminderHour'] ?? json['daily_reminder_hour'],
      dailyReminderMinute:
          json['dailyReminderMinute'] ?? json['daily_reminder_minute'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hintsEnabled': hintsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'dailyReminderEnabled': dailyReminderEnabled,
      'dailyReminderHour': dailyReminderHour,
      'dailyReminderMinute': dailyReminderMinute,
    };
  }

  UserSettings copyWith({
    bool? hintsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
    int? dailyReminderMinute,
  }) {
    return UserSettings(
      hintsEnabled: hintsEnabled ?? this.hintsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderHour: dailyReminderHour ?? this.dailyReminderHour,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
    );
  }
}
