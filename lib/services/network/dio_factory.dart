import 'package:dio/dio.dart';

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
