import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mathlearning/services/auth_service.dart';

/// One-time setup for widget tests.
///
/// This project uses singletons that expect basic initialization and plugins
/// that rely on SharedPreferences.
Future<void> bootstrapTests() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  FlutterLocalNotificationsPlatform.instance =
      _TestFlutterLocalNotificationsPlatform();
  await AuthService.instance.initialize();
}

class _TestFlutterLocalNotificationsPlatform
    extends AndroidFlutterLocalNotificationsPlugin {
  @override
  Future<bool> initialize({
    required AndroidInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {}

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    AndroidNotificationDetails? notificationDetails,
    required AndroidScheduleMode scheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {}

  @override
  Future<bool?> requestNotificationsPermission() async => true;
}

