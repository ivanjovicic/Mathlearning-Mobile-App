import 'dart:async';
import 'dart:math';

typedef RetryCondition = bool Function(Object error);
typedef RetryCallback = void Function(
  int attempt,
  Duration nextDelay,
  Object error,
);

class RetryPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final double multiplier;
  final Duration maxDelay;
  final bool withJitter;

  const RetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 300),
    this.multiplier = 2,
    this.maxDelay = const Duration(seconds: 3),
    this.withJitter = true,
  });
}

/// Reusable retry/backoff executor with optional network-awareness.
class RetryExecutor {
  final Future<bool> Function()? canRetry;

  const RetryExecutor({this.canRetry});

  Future<T> run<T>(
    Future<T> Function() action, {
    RetryPolicy policy = const RetryPolicy(),
    RetryCondition? retryIf,
    RetryCallback? onRetry,
  }) async {
    var attempt = 0;
    Object? lastError;
    StackTrace? lastStackTrace;

    while (attempt < policy.maxAttempts) {
      attempt++;
      try {
        return await action();
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;

        if (attempt >= policy.maxAttempts) break;
        if (retryIf != null && !retryIf(error)) break;
        if (canRetry != null) {
          final allowed = await canRetry!.call();
          if (!allowed) break;
        }

        final delay = _nextDelay(policy, attempt);
        onRetry?.call(attempt, delay, error);
        await Future.delayed(delay);
      }
    }

    if (lastError != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace ?? StackTrace.current);
    }
    throw StateError('RetryExecutor failed without error context');
  }

  Duration _nextDelay(RetryPolicy policy, int attempt) {
    final powFactor = pow(policy.multiplier, attempt - 1).toDouble();
    final millis = (policy.initialDelay.inMilliseconds * powFactor).round();
    var delay = Duration(milliseconds: millis);
    if (delay > policy.maxDelay) delay = policy.maxDelay;

    if (!policy.withJitter || delay.inMilliseconds <= 1) return delay;

    final jitter = Random().nextInt((delay.inMilliseconds * 0.2).round() + 1);
    return Duration(milliseconds: delay.inMilliseconds - jitter);
  }
}
