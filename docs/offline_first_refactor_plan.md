# Offline-First Refactor Plan

## New Folder Structure

```text
lib/offline/
  bootstrap/
    offline_first_module.dart
  bridge/
    legacy_offline_bridge.dart
  data/
    drift/
      app_offline_database.dart
      drift_local_database_service.dart
      daos/
        pending_operations_dao.dart
        sync_metadata_dao.dart
      tables/
        questions_table.dart
        user_progress_table.dart
        pending_operations_table.dart
        sync_metadata_table.dart
        content_bundles_table.dart
        bundle_items_table.dart
  domain/
    offline_answer_draft.dart
    offline_bundle.dart
    offline_operation.dart
  repositories/
    provider_offline_repository.dart
  services/
    local_database_service.dart
    offline_repository.dart
    sync_coordinator.dart
    sync_queue_manager.dart
  sync/
    drift_sync_queue_manager.dart
    provider_sync_coordinator.dart
```

## Phase Map For This Codebase

### Phase 1: Foundation

- `lib/services/offline_storage_service.dart`
  Target role: legacy import source only.
- `lib/services/offline_manager.dart`
  Target role: compatibility facade over `OfflineRepository + SyncCoordinator`.
- `lib/state/quiz_provider.dart`
  Target role: local-first writes through `OfflineRepository`.

### File-By-File Target Mapping

- `lib/services/offline_manager.dart`
  Split into:
  `lib/offline/repositories/provider_offline_repository.dart`
  `lib/offline/sync/provider_sync_coordinator.dart`
  `lib/offline/sync/drift_sync_queue_manager.dart`

- `lib/services/offline_storage_service.dart`
  Become:
  legacy import/export adapter only
  plus future topic/question import helper into Drift tables

- `lib/state/quiz_provider.dart`
  Replace direct calls to:
  `OfflineManager.submitAnswer`
  `OfflineManager.submitSrsUpdate`
  with:
  `OfflineRepository.submitQuizAnswer`
  and local Drift-backed question/progress reads

- `lib/state/progress_provider.dart`
  Replace ad-hoc cache and immediate server sync with:
  `user_progress` Drift table
  plus queued `syncProgress` operation

- `lib/widgets/offline_status_widget.dart`
  Replace legacy `pendingCountStream` with:
  `OfflineRepository.watchPendingOperationCount(userId)`
  and `sync_metadata.last_successful_sync`

- `lib/state/auth_provider.dart`
  After successful auth:
  initialize `OfflineFirstModule`
  run `LegacyOfflineBridge.bootstrapFromLegacyStorage()`
  then trigger `SyncCoordinator.triggerSync(userId: ...)`

- `lib/services/connectivity_service.dart`
  Keep as signal source in short term.
  Later add backend reachability probe before queue processing.

- `lib/services/progress_service.dart`
  Becomes API-only boundary used by `SyncCoordinator`, not by UI/provider directly.

- `lib/services/srs_service.dart`
  Becomes API-only boundary used by queued `updateSrs` operations.

- `lib/features/learning_map/providers/learning_map_provider.dart`
  Move cache writes from ad-hoc prefs to:
  `content_bundles` + `bundle_items`
  while reads still fallback through current provider until Phase 4.

### Phase 2: Queue + Sync

- Replace `_syncPendingAnswers()` in `lib/services/offline_manager.dart`
  with queue worker based on `pending_operations`.
- Move retry policy from `OfflineManager.retryWithBackoff`
  into `SyncCoordinator`.
- Use `idempotency_key` for `/api/quiz/answer` and future sync endpoints.

### Phase 3: Local Source Of Truth

- `lib/state/progress_provider.dart`
  Read/write from Drift `user_progress`.
- `lib/state/quiz_provider.dart`
  Read cached questions and pending state from Drift.
- `lib/widgets/offline_status_widget.dart`
  Watch Drift-backed pending count and last sync timestamp.

### Phase 4: Content Bundles

- `lib/features/learning_map/providers/learning_map_provider.dart`
  Move cache from ad-hoc SharedPreferences to bundle tables.
- `lib/services/adaptive_learning_service.dart`
  Persist path/recommendations/explanations in bundle storage.

### Phase 5: Legacy Removal

- Remove SharedPreferences queue keys from `OfflineStorageService`.
- Remove `pending_answers` and `user_progress` sqflite v1 table usage.
- Keep one migration import path only for already-installed users.

## Immediate Integration Boundaries

- `AuthProvider.autoLogin/login`
  After auth success: call `SyncCoordinator.triggerSync(userId: ...)`.
- `ConnectivityService`
  On reconnect: call `SyncCoordinator.onConnectivityRestored(userId)`.
- `OfflineManager`
  Short term: delegate new queue writes to `OfflineRepository`, keep old API.

## First Safe Refactor Sequence

1. Initialize `OfflineFirstModule` and `LegacyOfflineBridge` after auth.
2. Mirror new quiz answer writes into `pending_operations` while keeping legacy queue intact.
3. Switch `OfflineStatusWidget` pending counter to new queue.
4. Move `OfflineManager.syncPendingData()` internals to `SyncCoordinator`.
5. Delete legacy `pending_answers` write path only after parity verification.

## Data Migration Notes

- Legacy `pending_answers` rows become `pending_operations.submitQuizAnswer`.
- Legacy SRS pending prefs become `pending_operations.updateSrs`.
- Legacy cached questions should be imported into `questions_table` lazily by topic.
