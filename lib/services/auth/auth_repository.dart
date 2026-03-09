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
      final response = await _dio.post('/api/auth/login', data: {
        'Username': username,
        'Password': password,
      });

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

      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

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

  Future<ApiResult<Map<String, dynamic>>> register(String username, String password, String email) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
      });
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