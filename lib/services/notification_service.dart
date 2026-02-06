import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 1001;
  static const String _dailyChannelId = 'daily_study_reminder';
  static const String _dailyChannelName = 'Daily Study Reminder';
  static const String _dailyChannelDescription =
      'Daily reminder notifications for quiz practice';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(settings);

    tz.initializeTimeZones();
    try {
      final localTimezone = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone));
    } catch (e) {
      debugPrint('Notification timezone fallback: $e');
      tz.setLocalLocation(tz.UTC);
    }

    _initialized = true;
  }

  Future<bool> syncDailyReminder({
    required bool enabled,
    required TimeOfDay time,
    bool requestPermission = true,
  }) async {
    if (kIsWeb) return false;

    await initialize();

    if (!enabled) {
      await _notifications.cancel(_dailyReminderId);
      return true;
    }

    if (requestPermission) {
      final granted = await _requestPermission();
      if (!granted) {
        return false;
      }
    }

    await _notifications.cancel(_dailyReminderId);
    await _notifications.zonedSchedule(
      _dailyReminderId,
      'Math podsetnik',
      'Vreme je za kratki dnevni kviz.',
      _nextInstanceOf(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          channelDescription: _dailyChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'daily_reminder',
    );

    return true;
  }

  Future<bool> _requestPermission() async {
    var granted = true;

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final androidGranted = await androidImpl.requestNotificationsPermission();
      granted = granted && (androidGranted ?? true);
    }

    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final iosGranted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = granted && (iosGranted ?? false);
    }

    final macImpl = _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macImpl != null) {
      final macGranted = await macImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = granted && (macGranted ?? false);
    }

    return granted;
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
