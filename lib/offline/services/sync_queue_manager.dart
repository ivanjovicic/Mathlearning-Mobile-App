import '../domain/offline_operation.dart';

abstract class SyncQueueManager {
  Stream<int> watchPendingCount(String userId);

  Future<void> enqueueOperation(OfflineOperationRecord operation);

  Future<List<OfflineOperationRecord>> loadRunnableOperations({
    required String userId,
    required DateTime now,
    int limit = 25,
  });

  Future<void> markProcessing({
    required String operationId,
    required String leaseOwner,
    required DateTime leaseExpiresAt,
  });

  Future<void> markCompleted(String operationId);

  Future<void> markRetryableFailure({
    required String operationId,
    required int retryCount,
    required DateTime nextRetryAt,
    String? errorCode,
    String? errorMessage,
  });

  Future<void> markPermanentFailure({
    required String operationId,
    String? errorCode,
    String? errorMessage,
  });

  Future<void> recoverExpiredLeases(DateTime now);
}
