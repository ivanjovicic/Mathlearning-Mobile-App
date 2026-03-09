import '../data/drift/drift_local_database_service.dart';
import '../repositories/provider_offline_repository.dart';
import '../services/local_database_service.dart';
import '../services/offline_repository.dart';
import '../services/sync_coordinator.dart';
import '../services/sync_queue_manager.dart';
import '../sync/drift_sync_queue_manager.dart';
import '../sync/provider_sync_coordinator.dart';

class OfflineFirstModule {
  OfflineFirstModule._();

  static final OfflineFirstModule instance = OfflineFirstModule._();

  LocalDatabaseService? _databaseService;
  SyncQueueManager? _queueManager;
  SyncCoordinator? _syncCoordinator;
  OfflineRepository? _repository;

  Future<void> initialize() async {
    _databaseService ??= DriftLocalDatabaseService();
    final database = await _databaseService!.open();
    _queueManager ??= DriftSyncQueueManager(database);
    _syncCoordinator ??= ProviderSyncCoordinator(_queueManager!);
    await _syncCoordinator!.initialize();
    _repository ??= ProviderOfflineRepository(
      queueManager: _queueManager!,
      syncCoordinator: _syncCoordinator!,
    );
  }

  LocalDatabaseService get databaseService {
    final service = _databaseService;
    if (service == null) {
      throw StateError('OfflineFirstModule not initialized');
    }
    return service;
  }

  SyncQueueManager get queueManager {
    final manager = _queueManager;
    if (manager == null) {
      throw StateError('OfflineFirstModule not initialized');
    }
    return manager;
  }

  SyncCoordinator get syncCoordinator {
    final coordinator = _syncCoordinator;
    if (coordinator == null) {
      throw StateError('OfflineFirstModule not initialized');
    }
    return coordinator;
  }

  OfflineRepository get repository {
    final repo = _repository;
    if (repo == null) {
      throw StateError('OfflineFirstModule not initialized');
    }
    return repo;
  }
}
