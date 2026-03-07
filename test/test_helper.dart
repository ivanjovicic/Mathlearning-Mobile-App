import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void setupGlobalMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  TestWidgetsFlutterBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    secureStorageChannel,
    (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'read':
          return null; // Return mock data for read
        case 'write':
        case 'delete':
          return null; // Simulate successful write/delete
        default:
          throw PlatformException(
            code: 'Unimplemented',
            details: 'The method ${methodCall.method} is not implemented.',
          );
      }
    },
  );
}