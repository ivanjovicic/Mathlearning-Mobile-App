import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HttpClientAdapter originalAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.initialize();
    originalAdapter = AuthService.instance.client.httpClientAdapter;
  });

  tearDown(() {
    AuthService.instance.client.httpClientAdapter = originalAdapter;
  });

  test(
    'refresh failure notifies AuthProvider-facing session expiry stream',
    () async {
      var expiredEvents = 0;
      final subscription = AuthService.instance.sessionExpiredStream.listen((
        _,
      ) {
        expiredEvents += 1;
      });
      AuthService.instance.client.httpClientAdapter =
          _AlwaysUnauthorizedAdapter();

      await expectLater(
        AuthService.instance.client.get('/api/protected-resource'),
        throwsA(isA<DioException>()),
      );

      await Future<void>.delayed(Duration.zero);
      expect(expiredEvents, 1);
      expect(AuthService.instance.isLoggedIn, isFalse);

      await subscription.cancel();
    },
  );
}

class _AlwaysUnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      'unauthorized',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.textPlainContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
