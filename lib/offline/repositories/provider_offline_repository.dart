import 'dart:convert';

import '../domain/offline_answer_draft.dart';
import '../domain/offline_operation.dart';
import '../services/offline_repository.dart';
import '../services/sync_coordinator.dart';
import '../services/sync_queue_manager.dart';

class ProviderOfflineRepository implements OfflineRepository {
  ProviderOfflineRepository({
    required SyncQueueManager queueManager,
    required SyncCoordinator syncCoordinator,
  }) : _queueManager = queueManager,
       _syncCoordinator = syncCoordinator;

  final SyncQueueManager _queueManager;
  final SyncCoordinator _syncCoordinator;

  @override
  Stream<int> watchPendingOperationCount(String userId) {
    return _queueManager.watchPendingCount(userId);
  }

  @override
  Stream<List<OfflineOperationRecord>> watchPendingOperations(String userId) {
    return watchPendingOperationCount(userId).asyncMap((_) {
      return _queueManager.loadRunnableOperations(
        userId: userId,
        now: DateTime.now(),
        limit: 100,
      );
    });
  }

  @override
  Future<void> submitQuizAnswer(OfflineAnswerDraft draft) async {
    final now = DateTime.now();
    await _queueManager.enqueueOperation(
      OfflineOperationRecord(
        operationId: draft.idempotencyKey,
        userId: draft.userId,
        operationType: OfflineOperationType.submitQuizAnswer,
        entityType: 'quiz_answer',
        entityId: '${draft.quizId}:${draft.questionId}',
        payloadJson: jsonEncode({
          'quizId': draft.quizId,
          'questionId': draft.questionId,
          'selectedAnswer': draft.selectedAnswer,
          'timeSpentSeconds': draft.timeSpentSeconds,
          'isCorrect': draft.isCorrect,
          'answeredAt': draft.answeredAt.toIso8601String(),
        }),
        idempotencyKey: draft.idempotencyKey,
        status: OfflineOperationStatus.pending,
        retryCount: 0,
        priority: 100,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _syncCoordinator.triggerSync(userId: draft.userId);
  }

  @override
  Future<void> enqueueProgressSync({
    required String userId,
    required String payloadJson,
    required String idempotencyKey,
  }) async {
    final now = DateTime.now();
    await _queueManager.enqueueOperation(
      OfflineOperationRecord(
        operationId: idempotencyKey,
        userId: userId,
        operationType: OfflineOperationType.syncProgress,
        entityType: 'user_progress',
        entityId: userId,
        payloadJson: payloadJson,
        idempotencyKey: idempotencyKey,
        status: OfflineOperationStatus.pending,
        retryCount: 0,
        priority: 200,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _syncCoordinator.triggerSync(userId: userId);
  }

  @override
  Future<void> triggerBackgroundSync({required String userId}) {
    return _syncCoordinator.triggerSync(userId: userId);
  }
}
