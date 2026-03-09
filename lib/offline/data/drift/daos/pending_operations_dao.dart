import 'package:drift/drift.dart';

import '../app_offline_database.dart';
import '../tables/pending_operations_table.dart';

part 'pending_operations_dao.g.dart';

@DriftAccessor(tables: [PendingOperationsTable])
class PendingOperationsDao extends DatabaseAccessor<AppOfflineDatabase>
    with _$PendingOperationsDaoMixin {
  PendingOperationsDao(super.db);

  Stream<int> watchPendingCount(String userId) {
    final countExpression = pendingOperationsTable.operationId.count();
    final query = selectOnly(pendingOperationsTable)
      ..addColumns([countExpression])
      ..where(
        pendingOperationsTable.userId.equals(userId) &
            pendingOperationsTable.status.isIn(const ['pending', 'processing', 'failed']),
      );

    return query.watchSingle().map((row) => row.read(countExpression) ?? 0);
  }

  Future<void> insertOperation(PendingOperationsTableCompanion companion) {
    return into(pendingOperationsTable).insert(
      companion,
      mode: InsertMode.insertOrAbort,
    );
  }

  Future<List<PendingOperationsTableData>> loadRunnableOperations({
    required String userId,
    required DateTime now,
    int limit = 25,
  }) {
    final query = select(pendingOperationsTable)
      ..where(
        (tbl) =>
            tbl.userId.equals(userId) &
            tbl.status.isIn(const ['pending', 'failed']) &
            (tbl.nextRetryAt.isNull() | tbl.nextRetryAt.isSmallerOrEqualValue(now)),
      )
      ..orderBy([
        (tbl) => OrderingTerm.asc(tbl.priority),
        (tbl) => OrderingTerm.asc(tbl.createdAt),
      ])
      ..limit(limit);

    return query.get();
  }

  Future<void> markProcessing({
    required String operationId,
    required String leaseOwner,
    required DateTime leaseExpiresAt,
  }) {
    return (update(pendingOperationsTable)
          ..where((tbl) => tbl.operationId.equals(operationId)))
        .write(
      PendingOperationsTableCompanion(
        status: const Value('processing'),
        leaseOwner: Value(leaseOwner),
        leaseExpiresAt: Value(leaseExpiresAt),
        lastAttemptAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markCompleted(String operationId) {
    return (update(pendingOperationsTable)
          ..where((tbl) => tbl.operationId.equals(operationId)))
        .write(
      PendingOperationsTableCompanion(
        status: const Value('completed'),
        leaseOwner: const Value(null),
        leaseExpiresAt: const Value(null),
        errorCode: const Value(null),
        errorMessage: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markRetryableFailure({
    required String operationId,
    required int retryCount,
    required DateTime nextRetryAt,
    String? errorCode,
    String? errorMessage,
  }) {
    return (update(pendingOperationsTable)
          ..where((tbl) => tbl.operationId.equals(operationId)))
        .write(
      PendingOperationsTableCompanion(
        status: const Value('failed'),
        retryCount: Value(retryCount),
        nextRetryAt: Value(nextRetryAt),
        errorCode: Value(errorCode),
        errorMessage: Value(errorMessage),
        leaseOwner: const Value(null),
        leaseExpiresAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markPermanentFailure({
    required String operationId,
    String? errorCode,
    String? errorMessage,
  }) {
    return (update(pendingOperationsTable)
          ..where((tbl) => tbl.operationId.equals(operationId)))
        .write(
      PendingOperationsTableCompanion(
        status: const Value('failed'),
        nextRetryAt: const Value(null),
        errorCode: Value(errorCode),
        errorMessage: Value(errorMessage),
        leaseOwner: const Value(null),
        leaseExpiresAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> recoverExpiredLeases(DateTime now) {
    return (update(pendingOperationsTable)
          ..where(
            (tbl) =>
                tbl.status.equals('processing') &
                tbl.leaseExpiresAt.isSmallerThanValue(now),
          ))
        .write(
      PendingOperationsTableCompanion(
        status: const Value('pending'),
        leaseOwner: const Value(null),
        leaseExpiresAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
