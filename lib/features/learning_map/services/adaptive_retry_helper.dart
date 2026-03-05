import 'dart:async';
import 'dart:math';

import 'package:mathlearning/services/api_service.dart';
import 'package:mathlearning/services/connectivity_service.dart';

class RetryResult<T> {
  const RetryResult({required this.result, required this.usedRetry});

  final ApiResult<T> result;
  final bool usedRetry;
}

class AdaptiveRetryHelper {
  const AdaptiveRetryHelper({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(milliseconds: 500),
  });

  final int maxAttempts;
  final Duration baseDelay;

  Future<RetryResult<T>> run<T>(Future<ApiResult<T>> Function() request) async {
    var attempt = 0;
    var usedRetry = false;
    ApiResult<T>? lastResult;

    while (attempt < maxAttempts) {
      if (attempt > 0) {
        usedRetry = true;
      }

      if (attempt > 0 && !ConnectivityService.instance.isOnline) {
        break;
      }

      final result = await request();
      lastResult = result;
      final shouldRetry = _shouldRetry(result, attempt);
      if (!shouldRetry) {
        return RetryResult(result: result, usedRetry: usedRetry);
      }

      final delay = _resolveDelay(result, attempt);
      await Future<void>.delayed(delay);
      attempt += 1;
    }

    return RetryResult(
      result:
          lastResult ??
          ApiResult<T>(
            error: ApiError(message: 'Request failed after retries'),
          ),
      usedRetry: usedRetry,
    );
  }

  bool _shouldRetry<T>(ApiResult<T> result, int attempt) {
    if (result.data != null && result.error == null) {
      return false;
    }
    if (attempt + 1 >= maxAttempts) {
      return false;
    }
    if (result.isRateLimited) {
      return true;
    }
    final error = result.error;
    if (error == null) {
      return false;
    }
    if (error.dioErrorType != null) {
      return true;
    }
    final message = error.message.toLowerCase();
    return message.contains('timeout') ||
        message.contains('socket') ||
        message.contains('network');
  }

  Duration _resolveDelay<T>(ApiResult<T> result, int attempt) {
    if (result.isRateLimited && result.retryAfter != null) {
      return result.retryAfter!;
    }

    final multiplier = pow(2, attempt).toInt();
    final delayMs = baseDelay.inMilliseconds * multiplier;
    return Duration(milliseconds: delayMs.clamp(250, 6000));
  }
}
