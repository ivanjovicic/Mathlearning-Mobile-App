import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Math Learning',
      appUserModelId: 'com.mathlearning.app',
      guid: '5e1c1d9a-c748-4dc4-a2d4-f9a2a6e8f142',
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _notifications.initialize(settings: settings);

    tz.initializeTimeZones();
    try {
      final dynamic localTimezone = await FlutterTimezone.getLocalTimezone();
      String localTimezoneName = '';
      if (localTimezone is String) {
        localTimezoneName = localTimezone;
      } else if (localTimezone != null) {
        final dyn = localTimezone as dynamic;
        try {
          final candidate = dyn.name ??
              dyn.timeZoneName ??
              dyn.timeZoneId ??
              dyn.id ??
              dyn.value ??
              dyn.location ??
              dyn.tz ??
              dyn.toString();
          localTimezoneName = candidate?.toString() ?? '';
        } catch (_) {
          localTimezoneName = localTimezone.toString();
        }
      }

      if (localTimezoneName.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(localTimezoneName));
      } else {
        tz.setLocalLocation(tz.UTC);
      }
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
      await _notifications.cancel(id: _dailyReminderId);
      return true;
    }

    if (requestPermission) {
      final granted = await _requestPermission();
      if (!granted) {
        return false;
      }
    }

    await _notifications.cancel(id: _dailyReminderId);
    await _notifications.zonedSchedule(
      id: _dailyReminderId,
      title: 'Math podsetnik',
      body: 'Vreme je za kratki dnevni kviz.',
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          channelDescription: _dailyChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
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
