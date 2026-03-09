import '../domain/offline_answer_draft.dart';
import '../domain/offline_operation.dart';

abstract class OfflineRepository {
  Stream<int> watchPendingOperationCount(String userId);

  Stream<List<OfflineOperationRecord>> watchPendingOperations(String userId);

  Future<void> submitQuizAnswer(OfflineAnswerDraft draft);

  Future<void> enqueueProgressSync({
    required String userId,
    required String payloadJson,
    required String idempotencyKey,
  });

  Future<void> triggerBackgroundSync({required String userId});
}
