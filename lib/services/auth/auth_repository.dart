import 'package:dio/dio.dart';
import 'token_storage.dart';
import '../../models/token_pair.dart';
import '../../models/api_result.dart';

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository(this._dio, this._tokenStorage);

  Future<ApiResult<bool>> login(String username, String password) async {
    try {
      // Dev API expects /api/auth/login and capitalized body keys
      final response = await _dio.post(
        '/api/auth/login',
        data: {'Username': username, 'Password': password},
      );

      final tokenPair = TokenPair.fromJson(response.data);
      await _tokenStorage.saveRefreshToken(tokenPair.refresh);
      await _tokenStorage.saveAccessToken(tokenPair.access);

      return ApiSuccess(true);
    } on DioException catch (e) {
      return ApiFailure(ApiError.fromDio(e));
    } catch (e) {
      return ApiFailure(ApiError.fromDio(e));
    }
  }

  Future<ApiResult<bool>> refreshToken() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return ApiFailure(ApiError(message: 'No refresh token available'));
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 400) {
        await _tokenStorage.clear();
        final responseData = response.data;
        final message = responseData is Map<String, dynamic>
            ? (responseData['error']?.toString() ??
                  responseData['message']?.toString() ??
                  'Invalid or expired refresh token')
            : 'Invalid or expired refresh token';
        return ApiFailure(
          ApiError(
            message: message,
            code: statusCode,
            isUnauthorized: statusCode == 401,
          ),
        );
      }

      if (statusCode < 200 || statusCode >= 300) {
        return ApiFailure(
          ApiError(message: 'Refresh token request failed', code: statusCode),
        );
      }

      final tokenPair = TokenPair.fromJson(response.data);
      await _tokenStorage.saveRefreshToken(tokenPair.refresh);
      await _tokenStorage.saveAccessToken(tokenPair.access);

      return ApiSuccess(true);
    } on DioException catch (e) {
      return ApiFailure(ApiError.fromDio(e));
    } catch (e) {
      return ApiFailure(ApiError.fromDio(e));
    }
  }

  Future<ApiResult<Map<String, dynamic>>> register(
    String username,
    String password,
    String email,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {'username': username, 'password': password, 'email': email},
      );
      return ApiSuccess(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return ApiFailure(ApiError.fromDio(e));
    } catch (e) {
      return ApiFailure(ApiError.fromDio(e));
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
  }
}
