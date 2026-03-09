enum OfflineOperationStatus {
  pending,
  processing,
  failed,
  completed,
}

enum OfflineOperationType {
  submitQuizAnswer,
  updateSrs,
  syncProgress,
  refreshBundle,
}

class OfflineOperationRecord {
  const OfflineOperationRecord({
    required this.operationId,
    required this.userId,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.status,
    required this.retryCount,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.errorCode,
    this.errorMessage,
    this.dependsOnOperationId,
    this.leaseOwner,
    this.leaseExpiresAt,
  });

  final String operationId;
  final String userId;
  final OfflineOperationType operationType;
  final String entityType;
  final String entityId;
  final String payloadJson;
  final String idempotencyKey;
  final OfflineOperationStatus status;
  final int retryCount;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final String? errorCode;
  final String? errorMessage;
  final String? dependsOnOperationId;
  final String? leaseOwner;
  final DateTime? leaseExpiresAt;
}
