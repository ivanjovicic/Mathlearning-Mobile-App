import 'dart:async';
import 'package:dio/dio.dart';

import 'auth_repository.dart';
import 'token_storage.dart';
import '../../models/api_result.dart';

class AuthClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AuthRepository _authRepository;

  AuthClient(this._dio, this._tokenStorage, this._authRepository) {
    _dio.interceptors.add(
      _AuthInterceptor(_dio, _tokenStorage, _authRepository),
    );
  }
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final AuthRepository _authRepository;
  Completer<bool>? _refreshCompleter;

  _AuthInterceptor(this._dio, this._tokenStorage, this._authRepository);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        !_isAuthRoute(err.requestOptions.path)) {
      var completer = _refreshCompleter;
      if (completer == null) {
        completer = Completer<bool>();
        _refreshCompleter = completer;
        try {
          final refreshResult = await _authRepository.refreshToken();
          if (refreshResult is ApiSuccess<bool>) {
            completer.complete(refreshResult.data == true);
          } else {
            completer.complete(false);
          }
        } catch (_) {
          completer.complete(false);
        } finally {
          _refreshCompleter = null;
        }
      }

      final refreshSuccess = await completer.future;
      if (refreshSuccess == true) {
        final retryRequest = await _retry(err.requestOptions);
        return handler.resolve(retryRequest);
      } else {
        await _authRepository.logout();
        return handler.reject(err);
      }
    }
    handler.next(err);
  }

  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  bool _isAuthRoute(String path) =>
      path.startsWith('/auth') || path.startsWith('/api/auth');
}
