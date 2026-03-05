import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathlearning/services/network/retry_executor.dart';

void main() {
  test('RetryExecutor retries until success', () async {
    var attempts = 0;
    final executor = RetryExecutor(canRetry: () async => true);

    final value = await executor.run<int>(
      () async {
        attempts++;
        if (attempts < 3) {
          throw TimeoutException('temporary');
        }
        return 42;
      },
      policy: const RetryPolicy(initialDelay: Duration(milliseconds: 1)),
      retryIf: (error) => error is TimeoutException,
    );

    expect(value, 42);
    expect(attempts, 3);
  });

  test('RetryExecutor stops when canRetry reports offline', () async {
    var attempts = 0;
    final executor = RetryExecutor(canRetry: () async => false);

    expect(
      () => executor.run<void>(
        () async {
          attempts++;
          throw TimeoutException('offline');
        },
        retryIf: (_) => true,
      ),
      throwsA(isA<TimeoutException>()),
    );

    expect(attempts, 1);
  });
}
