import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mathlearning/services/auth_service.dart';

/// One-time setup for widget tests.
///
/// This project uses singletons that expect basic initialization and plugins
/// that rely on SharedPreferences.
void bootstrapTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  AuthService.instance.initialize();
}

