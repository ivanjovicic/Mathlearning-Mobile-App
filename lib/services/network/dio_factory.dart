import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../utils/config.dart';
import '../auth/token_storage.dart';

class DioFactory {
  static final TokenStorage _tokenStorage = TokenStorage();

  static Dio create({bool withAuth = true}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );

    // Log requests/responses in debug mode to help during development.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false, // avoid logging Authorization header
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    if (withAuth) {
      attachAuthHeaderInterceptor(dio);
    }

    return dio;
  }

  static void attachAuthHeaderInterceptor(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _tokenStorage.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
      ),
    );
  }
}
