import 'package:dio/dio.dart';

sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;

  ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final ApiError error;

  ApiFailure(this.error);
}

class ApiError {
  final String message;
  final int? code;
  final bool isNetworkError;
  final bool isUnauthorized;
  final bool isRateLimited;
  final Duration? retryAfter;

  ApiError({
    required this.message,
    this.code,
    this.isNetworkError = false,
    this.isUnauthorized = false,
    this.isRateLimited = false,
    this.retryAfter,
  });

  factory ApiError.fromDio(dynamic e) {
    try {
      if (e is DioException) {
        final status = e.response?.statusCode;
        final raHeader = e.response?.headers.value('retry-after');
        return ApiError(
          message: e.message ?? 'Network error',
          code: status,
          isNetworkError: e.type == DioExceptionType.unknown || e.type == DioExceptionType.connectionError,
          isUnauthorized: status == 401,
          isRateLimited: status == 429,
          retryAfter: raHeader != null ? Duration(seconds: int.tryParse(raHeader) ?? 0) : null,
        );
      }
    } catch (_) {}

    return ApiError(message: e?.toString() ?? 'Unknown error');
  }
}