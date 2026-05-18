import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/services/network/dio_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Accept-Language normalizes hidden saved language codes to English',
    () async {
      SharedPreferences.setMockInitialValues({'settings_language_code': 'de'});
      final adapter = _HeaderCaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      DioFactory.attachLanguageHeaderInterceptor(dio);

      await dio.get('/anything');

      expect(adapter.lastHeaders?['Accept-Language'], 'en');
    },
  );

  test(
    'Accept-Language normalizes hidden legacy language indexes to English',
    () async {
      SharedPreferences.setMockInitialValues({'settings_language': 3});
      final adapter = _HeaderCaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      DioFactory.attachLanguageHeaderInterceptor(dio);

      await dio.get('/anything');

      expect(adapter.lastHeaders?['Accept-Language'], 'en');
    },
  );
}

class _HeaderCaptureAdapter implements HttpClientAdapter {
  Map<String, dynamic>? lastHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastHeaders = Map<String, dynamic>.from(options.headers);
    return ResponseBody.fromString('ok', 200);
  }

  @override
  void close({bool force = false}) {}
}
