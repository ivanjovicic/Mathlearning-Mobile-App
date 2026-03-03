import 'dart:math';

import 'package:dio/dio.dart';

class RetryPolicy {
  final int maxRetries;
  final Duration baseDelay;

  RetryPolicy({this.maxRetries = 2, this.baseDelay = const Duration(seconds: 1)});

  Future<Response> executeWithRetry(Future<Response> Function() request) async {
    int attempt = 0;
    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        if (attempt >= maxRetries || !_shouldRetry(e)) {
          rethrow;
        }
        attempt++;
        await Future.delayed(_calculateBackoff(attempt));
      }
    }
  }

  bool _shouldRetry(DioException e) {
    return e.type == DioExceptionType.unknown || e.type == DioExceptionType.connectionError;
  }

  Duration _calculateBackoff(int attempt) {
    final jitterMs = (Random().nextDouble() * baseDelay.inMilliseconds).toInt();
    final backoffMs = (baseDelay.inMilliseconds * pow(2, attempt)).toInt();
    return Duration(milliseconds: backoffMs + jitterMs);
  }
}