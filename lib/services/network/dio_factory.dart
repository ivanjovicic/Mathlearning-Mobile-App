import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/config.dart';
import '../auth/token_storage.dart';

class DioFactory {
  static final TokenStorage _tokenStorage = TokenStorage();
  static const String _languageKey = 'settings_language';
  static const String _languageCodeKey = 'settings_language_code';

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

    attachLanguageHeaderInterceptor(dio);

    return dio;
  }

  static void attachLanguageHeaderInterceptor(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final languageCode = await _readLanguageCode();
            if (languageCode != null &&
                languageCode.isNotEmpty &&
                !options.headers.containsKey('Accept-Language')) {
              // Backend may still prefer persisted user settings; this header is a runtime hint.
              options.headers['Accept-Language'] = languageCode;
            }
          } catch (_) {
            // Do not block requests if language preference cannot be read.
          }
          handler.next(options);
        },
      ),
    );
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

  static Future<String?> _readLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();

    // Prefer language code (new explicit format) if present.
    final languageCode = prefs.getString(_languageCodeKey);
    if (languageCode != null && languageCode.isNotEmpty) {
      return _normalizeSelectableLanguageCode(languageCode);
    }

    // Fallback to old index format for backward compatibility.
    final languageIndex = prefs.getInt(_languageKey);
    switch (languageIndex) {
      case 0: // english
        return 'en';
      case 1: // serbian
        return 'sr';
      case 2: // german
        return 'en';
      case 3: // spanish
        return 'en';
      default:
        return null;
    }
  }

  static String _normalizeSelectableLanguageCode(String languageCode) {
    switch (languageCode.trim().toLowerCase()) {
      case 'sr':
        return 'sr';
      case 'en':
        return 'en';
      case 'de':
      case 'es':
        return 'en';
      default:
        return languageCode;
    }
  }
}
