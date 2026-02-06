import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hint_models.dart';
import '../models/user_settings.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

enum AppLanguage { english, serbian, german, spanish }

extension AppLanguageX on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.serbian:
        return 'Srpski';
      case AppLanguage.german:
        return 'Deutsch';
      case AppLanguage.spanish:
        return 'Espanol';
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  static const int totalGoals = 5;

  static const _hintsEnabledKey = 'settings_hints_enabled';
  static const _formulaHintEnabledKey = 'settings_formula_hint_enabled';
  static const _clueHintEnabledKey = 'settings_clue_hint_enabled';
  static const _eliminateHintEnabledKey = 'settings_eliminate_hint_enabled';
  static const _soundEnabledKey = 'settings_sound_enabled';
  static const _vibrationEnabledKey = 'settings_vibration_enabled';
  static const _dailyReminderEnabledKey = 'settings_daily_reminder_enabled';
  static const _dailyReminderMinutesKey = 'settings_daily_reminder_minutes';
  static const _languageKey = 'settings_language';
  static const _profileConfiguredKey = 'settings_profile_configured';
  static const _notificationsConfiguredKey =
      'settings_notifications_configured';
  static const _themeConfiguredKey = 'settings_theme_configured';
  static const _hintsConfiguredKey = 'settings_hints_configured';
  static const _feedbackConfiguredKey = 'settings_feedback_configured';

  bool _isLoaded = false;

  bool _hintsEnabled = true;
  bool _formulaHintEnabled = true;
  bool _clueHintEnabled = true;
  bool _eliminateHintEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _dailyReminderEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 18, minute: 0);
  AppLanguage _language = AppLanguage.serbian;

  bool _profileConfigured = false;
  bool _notificationsConfigured = false;
  bool _themeConfigured = false;
  bool _hintsConfigured = false;
  bool _feedbackConfigured = false;
  bool _lastReminderPermissionDenied = false;

  final _settingsService = SettingsService.instance;
  String? _userId; // Store user ID for API calls

  bool get isLoaded => _isLoaded;
  bool get hintsEnabled => _hintsEnabled;
  bool get formulaHintEnabled => _formulaHintEnabled;
  bool get clueHintEnabled => _clueHintEnabled;
  bool get eliminateHintEnabled => _eliminateHintEnabled;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get dailyReminderEnabled => _dailyReminderEnabled;
  TimeOfDay get dailyReminderTime => _dailyReminderTime;
  AppLanguage get language => _language;
  Locale get locale {
    switch (_language) {
      case AppLanguage.serbian:
        return const Locale('sr');
      case AppLanguage.german:
        return const Locale('de');
      case AppLanguage.spanish:
        return const Locale('es');
      case AppLanguage.english:
        return const Locale('en');
    }
  }

  bool get profileConfigured => _profileConfigured;
  bool get notificationsConfigured => _notificationsConfigured;
  bool get themeConfigured => _themeConfigured;
  bool get hintsConfigured => _hintsConfigured;
  bool get feedbackConfigured => _feedbackConfigured;
  bool get lastReminderPermissionDenied => _lastReminderPermissionDenied;

  void clearReminderPermissionStatus() {
    if (!_lastReminderPermissionDenied) return;
    _lastReminderPermissionDenied = false;
    notifyListeners();
  }

  int get completedGoals {
    var completed = 0;
    if (_profileConfigured) completed++;
    if (_notificationsConfigured) completed++;
    if (_themeConfigured) completed++;
    if (_hintsConfigured) completed++;
    if (_feedbackConfigured) completed++;
    return completed;
  }

  int get setupXp => completedGoals * 40;

  double get completionProgress {
    if (totalGoals == 0) return 0;
    return completedGoals / totalGoals;
  }

  SettingsProvider() {
    _load();
  }

  /// Set user ID for syncing settings with backend
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Sync settings from backend
  Future<void> syncFromBackend(String userId) async {
    try {
      final settings = await _settingsService.getUserSettings(userId);
      if (settings != null) {
        _hintsEnabled = settings.hintsEnabled;
        _soundEnabled = settings.soundEnabled;
        _vibrationEnabled = settings.vibrationEnabled;
        _dailyReminderEnabled = settings.dailyReminderEnabled;

        if (settings.dailyReminderHour != null &&
            settings.dailyReminderMinute != null) {
          _dailyReminderTime = TimeOfDay(
            hour: settings.dailyReminderHour!,
            minute: settings.dailyReminderMinute!,
          );
        }

        notifyListeners();
        await _persist();
      }
    } catch (e) {
      debugPrint('Error syncing settings from backend: $e');
    }
  }

  /// Sync settings to backend
  Future<void> _syncToBackend() async {
    if (_userId == null) return;

    try {
      final settings = UserSettings(
        hintsEnabled: _hintsEnabled,
        soundEnabled: _soundEnabled,
        vibrationEnabled: _vibrationEnabled,
        dailyReminderEnabled: _dailyReminderEnabled,
        dailyReminderHour: _dailyReminderTime.hour,
        dailyReminderMinute: _dailyReminderTime.minute,
      );

      await _settingsService.updateUserSettings(_userId!, settings);
    } catch (e) {
      debugPrint('Error syncing settings to backend: $e');
    }
  }

  bool isHintTypeEnabled(String hintType) {
    if (!_hintsEnabled) return false;
    switch (hintType) {
      case HintType.formula:
        return _formulaHintEnabled;
      case HintType.clue:
        return _clueHintEnabled;
      case HintType.eliminate:
        return _eliminateHintEnabled;
      default:
        return true;
    }
  }

  Future<void> markProfileConfigured() async {
    if (_profileConfigured) return;
    _profileConfigured = true;
    notifyListeners();
    await _persist();
  }

  Future<void> markThemeConfigured() async {
    if (_themeConfigured) return;
    _themeConfigured = true;
    notifyListeners();
    await _persist();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value && _profileConfigured) return;
    _language = value;
    _profileConfigured = true;
    notifyListeners();
    await _persist();
  }

  Future<void> setHintsEnabled(bool value) async {
    if (_hintsEnabled == value && _hintsConfigured) return;
    _hintsEnabled = value;
    _hintsConfigured = true;
    notifyListeners();
    await _persist();
    await _syncToBackend(); // Sync to backend
  }

  Future<void> setFormulaHintEnabled(bool value) async {
    if (_formulaHintEnabled == value && _hintsConfigured) return;
    _formulaHintEnabled = value;
    _hintsConfigured = true;
    notifyListeners();
    await _persist();
  }

  Future<void> setClueHintEnabled(bool value) async {
    if (_clueHintEnabled == value && _hintsConfigured) return;
    _clueHintEnabled = value;
    _hintsConfigured = true;
    notifyListeners();
    await _persist();
  }

  Future<void> setEliminateHintEnabled(bool value) async {
    if (_eliminateHintEnabled == value && _hintsConfigured) return;
    _eliminateHintEnabled = value;
    _hintsConfigured = true;
    notifyListeners();
    await _persist();
  }

  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled == value && _feedbackConfigured) return;
    _soundEnabled = value;
    _feedbackConfigured = true;
    notifyListeners();
    await _persist();
    await _syncToBackend(); // Sync to backend
  }

  Future<void> setVibrationEnabled(bool value) async {
    if (_vibrationEnabled == value && _feedbackConfigured) return;
    _vibrationEnabled = value;
    _feedbackConfigured = true;
    notifyListeners();
    await _persist();
    await _syncToBackend(); // Sync to backend
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    if (_dailyReminderEnabled == value && _notificationsConfigured) return;
    _lastReminderPermissionDenied = false;
    _dailyReminderEnabled = value;
    _notificationsConfigured = true;
    notifyListeners();

    final synced = await _syncReminderSchedule(requestPermission: value);
    if (value && !synced) {
      _dailyReminderEnabled = false;
      _lastReminderPermissionDenied = true;
      notifyListeners();
    }

    await _persist();
    await _syncToBackend(); // Sync to backend
  }

  Future<void> setReminderTime(TimeOfDay value) async {
    _lastReminderPermissionDenied = false;
    _dailyReminderTime = value;
    _notificationsConfigured = true;
    notifyListeners();

    if (_dailyReminderEnabled) {
      final synced = await _syncReminderSchedule(requestPermission: false);
      if (!synced) {
        _lastReminderPermissionDenied = true;
        notifyListeners();
      }
    }

    await _persist();
    await _syncToBackend(); // Sync to backend
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hintsEnabled = prefs.getBool(_hintsEnabledKey) ?? true;
      _formulaHintEnabled = prefs.getBool(_formulaHintEnabledKey) ?? true;
      _clueHintEnabled = prefs.getBool(_clueHintEnabledKey) ?? true;
      _eliminateHintEnabled = prefs.getBool(_eliminateHintEnabledKey) ?? true;
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
      _dailyReminderEnabled = prefs.getBool(_dailyReminderEnabledKey) ?? false;
      final reminderMinutes =
          prefs.getInt(_dailyReminderMinutesKey) ?? (18 * 60);
      _dailyReminderTime = _timeFromMinutes(reminderMinutes);

      final languageIndex = prefs.getInt(_languageKey) ?? _language.index;
      if (languageIndex >= 0 && languageIndex < AppLanguage.values.length) {
        _language = AppLanguage.values[languageIndex];
      }

      _profileConfigured = prefs.getBool(_profileConfiguredKey) ?? false;
      _notificationsConfigured =
          prefs.getBool(_notificationsConfiguredKey) ?? false;
      _themeConfigured = prefs.getBool(_themeConfiguredKey) ?? false;
      _hintsConfigured = prefs.getBool(_hintsConfiguredKey) ?? false;
      _feedbackConfigured = prefs.getBool(_feedbackConfiguredKey) ?? false;
    } catch (e) {
      debugPrint('Settings load fallback: $e');
    } finally {
      await _syncReminderSchedule(requestPermission: false);
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<bool> _syncReminderSchedule({required bool requestPermission}) async {
    try {
      return await NotificationService.instance.syncDailyReminder(
        enabled: _dailyReminderEnabled,
        time: _dailyReminderTime,
        requestPermission: requestPermission,
      );
    } catch (e) {
      debugPrint('Reminder schedule fallback: $e');
      return false;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hintsEnabledKey, _hintsEnabled);
      await prefs.setBool(_formulaHintEnabledKey, _formulaHintEnabled);
      await prefs.setBool(_clueHintEnabledKey, _clueHintEnabled);
      await prefs.setBool(_eliminateHintEnabledKey, _eliminateHintEnabled);
      await prefs.setBool(_soundEnabledKey, _soundEnabled);
      await prefs.setBool(_vibrationEnabledKey, _vibrationEnabled);
      await prefs.setBool(_dailyReminderEnabledKey, _dailyReminderEnabled);
      await prefs.setInt(
        _dailyReminderMinutesKey,
        _dailyReminderTime.hour * 60 + _dailyReminderTime.minute,
      );
      await prefs.setInt(_languageKey, _language.index);
      await prefs.setBool(_profileConfiguredKey, _profileConfigured);
      await prefs.setBool(
        _notificationsConfiguredKey,
        _notificationsConfigured,
      );
      await prefs.setBool(_themeConfiguredKey, _themeConfigured);
      await prefs.setBool(_hintsConfiguredKey, _hintsConfigured);
      await prefs.setBool(_feedbackConfiguredKey, _feedbackConfigured);
    } catch (e) {
      debugPrint('Settings save fallback: $e');
    }
  }

  TimeOfDay _timeFromMinutes(int minutes) {
    final normalized = minutes.clamp(0, 1439).toInt();
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }
}
