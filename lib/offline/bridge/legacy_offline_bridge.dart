import 'dart:convert';

import '../bootstrap/offline_first_module.dart';
import '../data/drift/app_offline_database.dart';
import '../../services/offline_storage_service.dart';

class LegacyOfflineBridge {
  LegacyOfflineBridge._();

  static final LegacyOfflineBridge instance = LegacyOfflineBridge._();

  Future<void> bootstrapFromLegacyStorage() async {
    await OfflineFirstModule.instance.initialize();
    final database =
        await OfflineFirstModule.instance.databaseService.open();
    await _importPendingAnswers(database);
    await _seedSyncMetadata(database);
  }

  Future<void> _importPendingAnswers(AppOfflineDatabase database) async {
    final legacyAnswers = await OfflineStorageService.getPendingAnswers();
    if (legacyAnswers.isEmpty) return;

    final existing = await database.pendingOperationsDao.watchPendingCount(
      _legacyUserId,
    ).first;
    if (existing > 0) return;

    for (final answer in legacyAnswers) {
      final questionId = answer['question_id'];
      final quizId = answer['quiz_id'];
      final answerValue = answer['answer'];
      if (questionId == null || quizId == null || answerValue == null) {
        continue;
      }

      final idempotencyKey =
          'legacy-answer-$quizId-$questionId-${answer['timestamp'] ?? DateTime.now().millisecondsSinceEpoch}';
      await database.pendingOperationsDao.insertOperation(
        PendingOperationsTableCompanion.insert(
          operationId: idempotencyKey,
          userId: _legacyUserId,
          operationType: 'submitQuizAnswer',
          entityType: 'quiz_answer',
          entityId: '$quizId:$questionId',
          payloadJson: jsonEncode(answer),
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            (answer['timestamp'] as num?)?.toInt() ??
                DateTime.now().millisecondsSinceEpoch,
          ),
          updatedAt: DateTime.now(),
          idempotencyKey: idempotencyKey,
        ),
      );
    }
  }

  Future<void> _seedSyncMetadata(AppOfflineDatabase database) {
    return database.syncMetadataDao.upsertValue(
      key: 'legacy_import_completed',
      valueJson: jsonEncode({'completedAt': DateTime.now().toIso8601String()}),
      updatedAt: DateTime.now(),
    );
  }

  String get _legacyUserId => 'legacy-default-user';
}
