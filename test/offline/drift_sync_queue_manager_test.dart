import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mathlearning/offline/data/drift/app_offline_database.dart';
import 'package:mathlearning/offline/domain/offline_operation.dart';
import 'package:mathlearning/offline/sync/drift_sync_queue_manager.dart';

void main() {
  group('DriftSyncQueueManager', () {
    late AppOfflineDatabase database;
    late DriftSyncQueueManager queueManager;

    setUp(() {
      database = AppOfflineDatabase.test(NativeDatabase.memory());
      queueManager = DriftSyncQueueManager(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('enqueueOperation persists runnable operation', () async {
      final now = DateTime(2026, 3, 8, 10, 0);
      await queueManager.enqueueOperation(
        OfflineOperationRecord(
          operationId: 'op-1',
          userId: 'user-1',
          operationType: OfflineOperationType.submitQuizAnswer,
          entityType: 'quiz_answer',
          entityId: 'quiz-1:question-7',
          payloadJson: '{"answer":"4"}',
          idempotencyKey: 'idem-1',
          status: OfflineOperationStatus.pending,
          retryCount: 0,
          priority: 100,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final operations = await queueManager.loadRunnableOperations(
        userId: 'user-1',
        now: now.add(const Duration(seconds: 1)),
      );

      expect(operations, hasLength(1));
      expect(operations.single.operationId, 'op-1');
      expect(operations.single.status, OfflineOperationStatus.pending);
    });
  });
}
