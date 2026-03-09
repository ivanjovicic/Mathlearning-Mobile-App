import 'package:drift/drift.dart' as drift;

import '../data/drift/app_offline_database.dart';
import '../domain/offline_operation.dart';
import '../services/sync_queue_manager.dart';

class DriftSyncQueueManager implements SyncQueueManager {
  DriftSyncQueueManager(this._database);

  final AppOfflineDatabase _database;

  @override
  Stream<int> watchPendingCount(String userId) {
    return _database.pendingOperationsDao.watchPendingCount(userId);
  }

  @override
  Future<void> enqueueOperation(OfflineOperationRecord operation) {
    return _database.pendingOperationsDao.insertOperation(
      PendingOperationsTableCompanion.insert(
        operationId: operation.operationId,
        userId: operation.userId,
        operationType: operation.operationType.name,
        entityType: operation.entityType,
        entityId: operation.entityId,
        payloadJson: operation.payloadJson,
        createdAt: operation.createdAt,
        updatedAt: operation.updatedAt,
        idempotencyKey: operation.idempotencyKey,
        retryCount: drift.Value(operation.retryCount),
        status: drift.Value(operation.status.name),
        lastAttemptAt: drift.Value(operation.lastAttemptAt),
        nextRetryAt: drift.Value(operation.nextRetryAt),
        errorCode: drift.Value(operation.errorCode),
        errorMessage: drift.Value(operation.errorMessage),
        dependsOnOperationId: drift.Value(operation.dependsOnOperationId),
        leaseOwner: drift.Value(operation.leaseOwner),
        leaseExpiresAt: drift.Value(operation.leaseExpiresAt),
        priority: drift.Value(operation.priority),
      ),
    );
  }

  @override
  Future<List<OfflineOperationRecord>> loadRunnableOperations({
    required String userId,
    required DateTime now,
    int limit = 25,
  }) async {
    final rows = await _database.pendingOperationsDao.loadRunnableOperations(
      userId: userId,
      now: now,
      limit: limit,
    );
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<void> markCompleted(String operationId) {
    return _database.pendingOperationsDao.markCompleted(operationId);
  }

  @override
  Future<void> markPermanentFailure({
    required String operationId,
    String? errorCode,
    String? errorMessage,
  }) {
    return _database.pendingOperationsDao.markPermanentFailure(
      operationId: operationId,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<void> markProcessing({
    required String operationId,
    required String leaseOwner,
    required DateTime leaseExpiresAt,
  }) {
    return _database.pendingOperationsDao.markProcessing(
      operationId: operationId,
      leaseOwner: leaseOwner,
      leaseExpiresAt: leaseExpiresAt,
    );
  }

  @override
  Future<void> markRetryableFailure({
    required String operationId,
    required int retryCount,
    required DateTime nextRetryAt,
    String? errorCode,
    String? errorMessage,
  }) {
    return _database.pendingOperationsDao.markRetryableFailure(
      operationId: operationId,
      retryCount: retryCount,
      nextRetryAt: nextRetryAt,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<void> recoverExpiredLeases(DateTime now) {
    return _database.pendingOperationsDao.recoverExpiredLeases(now);
  }

  OfflineOperationRecord _mapRow(PendingOperationsTableData row) {
    return OfflineOperationRecord(
      operationId: row.operationId,
      userId: row.userId,
      operationType: OfflineOperationType.values.byName(row.operationType),
      entityType: row.entityType,
      entityId: row.entityId,
      payloadJson: row.payloadJson,
      idempotencyKey: row.idempotencyKey,
      status: OfflineOperationStatus.values.byName(row.status),
      retryCount: row.retryCount,
      priority: row.priority,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastAttemptAt: row.lastAttemptAt,
      nextRetryAt: row.nextRetryAt,
      errorCode: row.errorCode,
      errorMessage: row.errorMessage,
      dependsOnOperationId: row.dependsOnOperationId,
      leaseOwner: row.leaseOwner,
      leaseExpiresAt: row.leaseExpiresAt,
    );
  }
}
